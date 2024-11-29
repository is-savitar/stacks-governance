(define-fungible-token governance-token)

;; Define error codes for token operations
(define-constant ERR_INSUFFICIENT_BALANCE (err u100))
(define-constant ERR_TOKEN_TRANSFER_FAILED (err u101))

;; Mint tokens to a specific recipient
(define-public (mint-tokens (amount uint) (recipient principal))
    (begin
        (try! (ft-mint? governance-token amount recipient))
        (ok true)
    )
)

;; Transfer tokens between principals
(define-public (transfer-tokens (amount uint) (sender principal) (recipient principal))
    (ft-transfer? governance-token amount sender recipient)
)

;; Get token balance for a principal
(define-read-only (get-balance (account principal))
    (ft-get-balance governance-token account)
)
