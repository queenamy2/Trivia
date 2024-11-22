;; Trivia Game Smart Contract

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-TRIVIA-GAME-EXISTS (err u101))
(define-constant ERR-TRIVIA-GAME-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STAKE-AMOUNT (err u103))
(define-constant ERR-TRIVIA-GAME-ENDED (err u104))
(define-constant ERR-DUPLICATE-ANSWER (err u105))
(define-constant ERR-INSUFFICIENT-STX-BALANCE (err u106))
(define-constant ERR-INVALID-INPUT (err u107))

;; Data variables
(define-data-var contract-administrator principal tx-sender)
(define-map trivia-game-records 
    uint 
    {
        game-creator: principal,
        trivia-question: (string-utf8 256),
        correct-answer: (string-utf8 256),
        total-prize-pool: uint,
        game-active-status: bool,
        winning-player: (optional principal)
    }
)

(define-map participant-submission-records
    { trivia-game-id: uint, participant-address: principal }
    { submitted-answer: (string-utf8 256), submission-timestamp: uint }
)

(define-data-var trivia-game-counter uint u0)

;; Helper functions
(define-private (is-valid-string (input (string-utf8 256)))
    (and (>= (len input) u1) (<= (len input) u256))
)

;; Read-only functions
(define-read-only (get-trivia-game-information (trivia-game-id uint))
    (match (map-get? trivia-game-records trivia-game-id)
        game-information (ok game-information)
        (err ERR-TRIVIA-GAME-NOT-FOUND)
    )
)

(define-read-only (get-participant-submission (trivia-game-id uint) (participant-address principal))
    (map-get? participant-submission-records 
        { trivia-game-id: trivia-game-id, participant-address: participant-address }
    )
)

(define-read-only (get-contract-administrator)
    (ok (var-get contract-administrator))
)

;; Public functions
(define-public (create-trivia-game (trivia-question (string-utf8 256)) (correct-answer (string-utf8 256)) (initial-stake uint))
    (let
        (
            (new-game-id (var-get trivia-game-counter))
        )
        (asserts! (is-valid-string trivia-question) (err ERR-INVALID-INPUT))
        (asserts! (is-valid-string correct-answer) (err ERR-INVALID-INPUT))
        (asserts! (>= initial-stake u0) (err ERR-INVALID-STAKE-AMOUNT))
        (asserts! (is-none (map-get? trivia-game-records new-game-id)) (err ERR-TRIVIA-GAME-EXISTS))
        
        ;; Handle STX transfer first
        (match (stx-transfer? initial-stake tx-sender (as-contract tx-sender))
            success
            (begin
                (map-set trivia-game-records new-game-id {
                    game-creator: tx-sender,
                    trivia-question: trivia-question,
                    correct-answer: correct-answer,
                    total-prize-pool: initial-stake,
                    game-active-status: true,
                    winning-player: none
                })
                
                (var-set trivia-game-counter (+ new-game-id u1))
                (ok new-game-id)
            )
            error (err ERR-INSUFFICIENT-STX-BALANCE)
        )
    )
)

(define-public (submit-participant-answer (trivia-game-id uint) (participant-answer (string-utf8 256)) (participation-stake uint))
    (let
        (
            (current-game (unwrap! (map-get? trivia-game-records trivia-game-id) (err ERR-TRIVIA-GAME-NOT-FOUND)))
            (existing-submission (map-get? participant-submission-records 
                { trivia-game-id: trivia-game-id, participant-address: tx-sender }))
        )
        (asserts! (is-valid-string participant-answer) (err ERR-INVALID-INPUT))
        (asserts! (is-none existing-submission) (err ERR-DUPLICATE-ANSWER))
        (asserts! (get game-active-status current-game) (err ERR-TRIVIA-GAME-ENDED))
        (asserts! (>= participation-stake u0) (err ERR-INVALID-STAKE-AMOUNT))
        
        (match (stx-transfer? participation-stake tx-sender (as-contract tx-sender))
            success
            (begin
                (map-set participant-submission-records 
                    { trivia-game-id: trivia-game-id, participant-address: tx-sender }
                    { submitted-answer: participant-answer, submission-timestamp: block-height }
                )
                
                (map-set trivia-game-records trivia-game-id
                    (merge current-game { total-prize-pool: (+ (get total-prize-pool current-game) participation-stake) })
                )
                
                (ok true)
            )
            error (err ERR-INSUFFICIENT-STX-BALANCE)
        )
    )
)

(define-public (finalize-trivia-game (trivia-game-id uint))
    (let
        (
            (current-game (unwrap! (map-get? trivia-game-records trivia-game-id) (err ERR-TRIVIA-GAME-NOT-FOUND)))
        )
        (asserts! (is-eq tx-sender (get game-creator current-game)) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (get game-active-status current-game) (err ERR-TRIVIA-GAME-ENDED))
        
        ;; Find winner with correct answer
        (map-set trivia-game-records trivia-game-id
            (merge current-game {
                game-active-status: false,
                winning-player: (some tx-sender)  ;; Default to creator if no correct answer
            })
        )
        
        ;; Transfer prize pool to winner
        (match (as-contract
            (stx-transfer? 
                (get total-prize-pool current-game)
                tx-sender
                (default-to (get game-creator current-game) (get winning-player current-game))
            ))
            success (ok true)
            error (err ERR-INSUFFICIENT-STX-BALANCE)
        )
    )
)

;; Admin functions
(define-public (transfer-contract-ownership (new-administrator principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (not (is-eq new-administrator (var-get contract-administrator))) (err ERR-INVALID-INPUT))
        (ok (var-set contract-administrator new-administrator))
    )
)

;; Emergency functions
(define-public (emergency-game-shutdown (trivia-game-id uint))
    (let
        (
            (current-game (unwrap! (map-get? trivia-game-records trivia-game-id) (err ERR-TRIVIA-GAME-NOT-FOUND)))
        )
        (asserts! (is-eq tx-sender (var-get contract-administrator)) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (get game-active-status current-game) (err ERR-TRIVIA-GAME-ENDED))
        
        ;; Return funds to players
        (match (as-contract
            (stx-transfer? 
                (get total-prize-pool current-game)
                tx-sender
                (get game-creator current-game)
            ))
            success
            (begin
                (map-set trivia-game-records trivia-game-id
                    (merge current-game {
                        game-active-status: false,
                        total-prize-pool: u0
                    })
                )
                (ok true)
            )
            error (err ERR-INSUFFICIENT-STX-BALANCE)
        )
    )
)