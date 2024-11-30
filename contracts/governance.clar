;; Governance Contract

;; Use the governance token
(use-trait governance-token-trait .governance-token.governance-token)

;; Define data vars
(define-data-var proposal-count uint u0)
(define-map proposals
  { proposal-id: uint }
  {
    description: (string-utf8 256),
    vote-count-for: uint,
    vote-count-against: uint,
    end-block-height: uint,
    executed: bool,
    proposer: principal
  }
)

;; Constants
(define-constant min-proposal-duration u1440) ;; Minimum duration in blocks (approximately 10 days)
(define-constant quorum-percentage u30) ;; 30% quorum required
(define-constant contract-owner tx-sender)

;; Create a new proposal
(define-public (create-proposal (description (string-utf8 256)) (duration uint) (governance-token <governance-token-trait>))
  (let
    (
      (proposal-id (+ (var-get proposal-count) u1))
      (end-block-height (+ block-height duration))
    )
    (asserts! (>= duration min-proposal-duration) (err u200))
    (asserts! (>= (unwrap-panic (contract-call? governance-token get-balance tx-sender)) u100000000) (err u201))
    (map-set proposals
      { proposal-id: proposal-id }
      {
        description: description,
        vote-count-for: u0,
        vote-count-against: u0,
        end-block-height: end-block-height,
        executed: false,
        proposer: tx-sender
      }
    )
    (var-set proposal-count proposal-id)
    (ok proposal-id)
  )
)
