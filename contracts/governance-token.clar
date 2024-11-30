;; Governance Token Contract

;; Define the token
(define-fungible-token governance-token)

;; Define data vars
(define-data-var token-name (string-ascii 32) "Governance Token")
(define-data-var token-symbol (string-ascii 10) "GOV")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)

;; Define the contract owner
(define-constant contract-owner tx-sender)

;; Mint function (only contract owner can mint)
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u100))
    (ok (ft-mint? governance-token amount recipient))
  )
)

;; Get balance function
(define-read-only (get-balance (account principal))
  (ok (ft-get-balance governance-token account))
)


;; Get token name
(define-read-only (get-name)
  (ok (var-get token-name))
)

;; Get token symbol
(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

;; Get token URI
(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Get token decimals
(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)
