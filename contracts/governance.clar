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


(module
  (import "builtin" "print" (func $print (param i32)))
  (import "builtin" "abort" (func $abort (param i32)))

  ;; Define the governance token trait
  (type <governance-token-trait>
    (func (param i32) (result i32)) ;; get-balance
  )

  ;; Define the proposal struct
  (type $proposal (struct (field proposal-id u32) (field description (array u8)) (field start-block-height u32) (field end-block-height u32) (field vote-count-for u32) (field vote-count-against u32) (field executed bool)))

  ;; Define a global variable to store proposals
  (global $proposals (mut (ref (array $proposal))) (i32.const 0))

  ;; Define a global variable for quorum percentage
  (global $quorum-percentage (mut i32) (i32.const 51))

  ;; Function to create a new proposal
  (func (export "create-proposal") (param $description (array u8)) (param $start-block-height u32) (param $end-block-height u32)
    (local $proposal-id u32)
    (local $new-proposal (ref $proposal))

    ;; Generate a unique proposal ID (replace with a more robust method if needed)
    (local.set $proposal-id (i32.add (global.get $proposal-id-counter) (i32.const 1)))
    (global.set $proposal-id-counter (i32.add (global.get $proposal-id-counter) (i32.const 1)))

    ;; Create a new proposal
    (local.set $new-proposal (ref.new $proposal))
    (ref.set (local.get $new-proposal) (field proposal-id) (local.get $proposal-id))
    (ref.set (local.get $new-proposal) (field description) (local.get $description))
    (ref.set (local.get $new-proposal) (field start-block-height) (local.get $start-block-height))
    (ref.set (local.get $new-proposal) (field end-block-height) (local.get $end-block-height))
    (ref.set (local.get $new-proposal) (field vote-count-for) (i32.const 0))
    (ref.set (local.get $new-proposal) (field vote-count-against) (i32.const 0))
    (ref.set (local.get $new-proposal) (field executed) (i32.const 0))

    ;; Add the proposal to the proposals array
    (global.set $proposals (array.append (global.get $proposals) (local.get $new-proposal)))

    (local.get $proposal-id)
  )

  ;; Function to cast a vote
  (func (export "vote") (param $proposal-id u32) (param $vote bool) (param $governance-token <governance-token-trait>)
    (local $proposal (ref $proposal))
    (local $index u32)

    ;; Find the proposal
    (local.set $index (i32.const 0))
    (loop $loop
      (br_if $end (i32.eq (local.get $index) (array.len (global.get $proposals))))
      (ref.set $proposal (array.get (global.get $proposals) (local.get $index)) )
      (br_if $found (i32.eq (ref.get (local.get $proposal) (field proposal-id)) (local.get $proposal-id)))
      (local.set $index (i32.add (local.get $index) (i32.const 1)))
      (br $loop)
    )
    (block $end (unreachable))
    (block $found
      (if (local.get $vote)
        (ref.set (local.get $proposal) (field vote-count-for) (i32.add (ref.get (local.get $proposal) (field vote-count-for)) (i32.const 1)))
        (ref.set (local.get $proposal) (field vote-count-against) (i32.add (ref.get (local.get $proposal) (field vote-count-against)) (i32.const 1)))
      )
      (ok true)
    )
  )

  ;; Execute a proposal
  (define-public (execute-proposal (proposal-id uint) (governance-token <governance-token-trait>))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err u400)))
      (total-votes (+ (get vote-count-for proposal) (get vote-count-against proposal)))
      (total-supply (unwrap-panic (contract-call? governance-token get-balance contract-owner)))
    )
    (asserts! (>= block-height (get end-block-height proposal)) (err u401))
    (asserts! (not (get executed proposal)) (err u402))
    (asserts! (>= (* total-votes u100) (* total-supply quorum-percentage)) (err u403))
    (asserts! (> (get vote-count-for proposal) (get vote-count-against proposal)) (err u404))
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { executed: true })
    )
    ;; Here you would typically call a function to implement the proposal
    ;; For this example, we'll just return success
    (ok true)
  )
)

  (global $proposal-id-counter (mut i32) (i32.const 0))

)
