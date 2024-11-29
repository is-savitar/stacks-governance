(define-fungible-token governance-token)

;; Define error codes for token operations
(define-constant ERR_INSUFFICIENT_BALANCE (err u100))
(define-constant ERR_TOKEN_TRANSFER_FAILED (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_INVALID_RECIPIENT (err u103))
(define-constant ERR_UNAUTHORIZED (err u104))

;; Mint tokens to a specific recipient
(define-public (mint-tokens (amount uint) (recipient principal))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR_UNAUTHORIZED)
        (try! (as-contract (ft-mint? governance-token amount recipient)))
        (ok true)
    )
)

;; Transfer tokens between principals
(define-public (transfer-tokens (amount uint) (recipient principal))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq tx-sender recipient)) ERR_INVALID_RECIPIENT)
        (ft-transfer? governance-token amount tx-sender recipient)
    )
)

;; Get token balance for a principal
(define-read-only (get-balance (account principal))
    (ft-get-balance governance-token account)
)
