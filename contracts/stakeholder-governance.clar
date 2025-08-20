;; Veridex Stakeholder Governance Contract
;; Clarity v2
;; Implements decentralized governance with token-weighted voting, proposal management, and reward distribution

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-PROPOSAL-NOT-FOUND u101)
(define-constant ERR-PROPOSAL-EXPIRED u102)
(define-constant ERR-ALREADY-VOTED u103)
(define-constant ERR-INSUFFICIENT-STAKE u104)
(define-constant ERR-QUORUM-NOT-MET u105)
(define-constant ERR-INVALID-REWARD u106)
(define-constant ERR-CONTRACT-PAUSED u107)
(define-constant ERR-INVALID-PROPOSAL u108)
(define-constant ERR-ZERO-ADDRESS u109)

;; Governance metadata
(define-constant VOTING_PERIOD u1440) ;; ~1 day in blocks (10 min/block)
(define-constant MIN_QUORUM u5000) ;; 50% quorum (basis points, 10000 = 100%)
(define-constant MIN_PROPOSAL_STAKE u1000) ;; Minimum stake to propose
(define-constant REWARD_POOL u1000000) ;; Reward pool for active voters

;; Contract state
(define-data-var admin principal tx-sender)
(define-data-var paused bool false)
(define-data-var total-staked uint u0)
(define-data-var proposal-count uint u0)

;; Data maps
(define-map proposals
  { proposal-id: uint }
  { proposer: principal, description: (string-ascii 256), start-block: uint, end-block: uint, yes-votes: uint, no-votes: uint, executed: bool }
)
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote-weight: uint, vote: bool } ;; true = yes, false = no
)
(define-map voter-rewards principal uint)

;; Private helper: is-admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Private helper: ensure not paused
(define-private (ensure-not-paused)
  (asserts! (not (var-get paused)) (err ERR-CONTRACT-PAUSED))
)

;; Private helper: check valid proposal
(define-private (is-valid-proposal (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal
    (and (not (get executed proposal)) (>= (get end-block proposal) block-height))
    false
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-eq new-admin 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (var-set admin new-admin)
    (ok true)
  )
)

;; Pause/unpause contract
(define-public (set-paused (pause bool))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set paused pause)
    (ok pause)
  )
)

;; Create a new proposal
(define-public (create-proposal (description (string-ascii 256)) (stake-amount uint))
  (begin
    (ensure-not-paused)
    (asserts! (>= stake-amount MIN_PROPOSAL_STAKE) (err ERR-INSUFFICIENT-STAKE))
    ;; Assumes external token contract for staking
    (try! (contract-call? .food-batch-nft stake stake-amount))
    (let
      (
        (proposal-id (+ (var-get proposal-count) u1))
        (start-block block-height)
        (end-block (+ block-height VOTING_PERIOD))
      )
      (map-set proposals
        { proposal-id: proposal-id }
        { proposer: tx-sender, description: description, start-block: start-block, end-block: end-block, yes-votes: u0, no-votes: u0, executed: false }
      )
      (var-set proposal-count proposal-id)
      (ok proposal-id)
    )
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-choice bool) (vote-weight uint))
  (begin
    (ensure-not-paused)
    (asserts! (is-valid-proposal proposal-id) (err ERR-PROPOSAL-EXPIRED))
    (asserts! (is-none? (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) (err ERR-ALREADY-VOTED))
    (asserts! (>= vote-weight u1) (err ERR-INSUFFICIENT-STAKE))
    ;; Assumes external token contract for vote weight
    (try! (contract-call? .food-batch-nft stake vote-weight))
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote-weight: vote-weight, vote: vote-choice }
    )
    (match (map-get? proposals { proposal-id: proposal-id })
      proposal
      (begin
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal
            (if vote-choice
              { yes-votes: (+ (get yes-votes proposal) vote-weight) }
              { no-votes: (+ (get no-votes proposal) vote-weight) }
            )
          )
        )
        (ok true)
      )
      (err ERR-PROPOSAL-NOT-FOUND)
    )
  )
)

;; Execute a proposal if quorum and majority are met
(define-public (execute-proposal (proposal-id uint))
  (begin
    (ensure-not-paused)
    (match (map-get? proposals { proposal-id: proposal-id })
      proposal
      (begin
        (asserts! (>= block-height (get end-block proposal)) (err ERR-PROPOSAL-EXPIRED))
        (asserts! (not (get executed proposal)) (err ERR-INVALID-PROPOSAL))
        (let
          (
            (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
            (quorum-reached (>= (* total-votes u10000) (* (var-get total-staked) MIN_QUORUM)))
            (majority-reached (> (get yes-votes proposal) (get no-votes proposal)))
          )
          (asserts! quorum-reached (err ERR-QUORUM-NOT-MET))
          (asserts! majority-reached (err ERR-QUORUM-NOT-MET))
          (map-set proposals
            { proposal-id: proposal-id }
            (merge proposal { executed: true })
          )
          (try! (distribute-rewards proposal-id))
          (ok true)
        )
      )
      (err ERR-PROPOSAL-NOT-FOUND)
    )
  )
)

;; Distribute rewards to voters (simplified reward logic)
(define-private (distribute-rewards (proposal-id uint))
  (let
    (
      (total-votes (match (map-get? proposals { proposal-id: proposal-id })
        proposal (+ (get yes-votes proposal) (get no-votes proposal))
        u0
      ))
      (reward-per-vote (if (> total-votes u0) (/ REWARD_POOL total-votes) u0))
    )
    (asserts! (> reward-per-vote u0) (err ERR-INVALID-REWARD))
    ;; Simulate reward distribution (assumes external token contract)
    (ok true)
  )
)

;; Update total staked amount (called by external staking contract)
(define-public (update-total-staked (new-total uint))
  (begin
    (asserts! (is-eq tx-sender .food-batch-nft) (err ERR-NOT-AUTHORIZED))
    (var-set total-staked new-total)
    (ok true)
  )
)

;; Read-only: get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (ok proposal)
    (err ERR-PROPOSAL-NOT-FOUND)
  )
)

;; Read-only: get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (match (map-get? votes { proposal-id: proposal-id, voter: voter })
    vote (ok vote)
    (err ERR-NOT-AUTHORIZED)
  )
)

;; Read-only: get total staked
(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)

;; Read-only: get admin
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Read-only: check if paused
(define-read-only (is-paused)
  (ok (var-get paused))
)