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

(import governance-token)

(define-constant ZERO u0)
(define-constant ONE u1)

;; Governance token trait
(trait governance-token-trait
  (get-balance (owner principal) -> uint)
)


;; Proposal structure
(define-data-var proposals
  { proposal-id: uint }
  {
    proposer: principal,
    description: string,
    start-block-height: uint,
    end-block-height: uint,
    vote-count-for: uint,
    vote-count-against: uint
  }
)

;; Create a new proposal
(define-public (create-proposal (description string) (end-block-height uint) (governance-token <governance-token-trait>))
  (let
    (
      (proposal-id (+ (length (get proposals)) ONE))
    )
    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        description: description,
        start-block-height: block-height,
        end-block-height: end-block-height,
        vote-count-for: ZERO,
        vote-count-against: ZERO
      }
    )
    (ok proposal-id)
  )
)

(define-map votes
  { voter: principal, proposal-id: uint }
  { in-favor: bool }
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (in-favor bool) (governance-token <governance-token-trait>))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err u300)))
      (voter-balance (unwrap-panic (contract-call? governance-token get-balance tx-sender)))
    )
    (asserts! (< block-height (get end-block-height proposal)) (err u301))
    (asserts! (is-none (map-get? votes { voter: tx-sender, proposal-id: proposal-id })) (err u302))
    (asserts! (> voter-balance u0) (err u303))
    (map-set votes
      { voter: tx-sender, proposal-id: proposal-id }
      { in-favor: in-favor }
    )
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        vote-count-for: (if in-favor (+ (get vote-count-for proposal) voter-balance) (get vote-count-for proposal)),
        vote-count-against: (if in-favor (get vote-count-against proposal) (+ (get vote-count-against proposal) voter-balance))
      })
    )
    (ok true)
  )
)
