;; Define data structures
(define-map permits
    { permit-id: uint }
    {
        owner: principal,
        status: (string-ascii 20),
        property-address: (string-ascii 100),
        permit-type: (string-ascii 50),
        issue-date: uint,
        expiry-date: uint,
        approved-by: (optional principal)
    }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))

;; Data vars
(define-data-var permit-nonce uint u0)

;; Private functions
(define-private (is-admin (caller principal))
    (is-eq caller contract-owner)
)

;; Public functions
(define-public (submit-permit-application 
    (property-address (string-ascii 100))
    (permit-type (string-ascii 50))
    (expiry-date uint)
)
    (let
        (
            (permit-id (+ (var-get permit-nonce) u1))
        )
        (try! (map-insert permits
            { permit-id: permit-id }
            {
                owner: tx-sender,
                status: "PENDING",
                property-address: property-address,
                permit-type: permit-type,
                issue-date: block-height,
                expiry-date: expiry-date,
                approved-by: none
            }
        ))
        (var-set permit-nonce permit-id)
        (ok permit-id)
    )
)

(define-public (approve-permit (permit-id uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
        )
        (if (is-admin tx-sender)
            (begin
                (try! (map-set permits
                    { permit-id: permit-id }
                    (merge permit {
                        status: "APPROVED",
                        approved-by: (some tx-sender)
                    })
                ))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-public (reject-permit (permit-id uint))
    (let
        (
            (permit (unwrap! (map-get? permits { permit-id: permit-id }) err-not-found))
        )
        (if (is-admin tx-sender)
            (begin
                (try! (map-set permits
                    { permit-id: permit-id }
                    (merge permit {
                        status: "REJECTED",
                        approved-by: (some tx-sender)
                    })
                ))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-read-only (get-permit (permit-id uint))
    (ok (map-get? permits { permit-id: permit-id }))
)

(define-read-only (get-permit-status (permit-id uint))
    (match (map-get? permits { permit-id: permit-id })
        permit (ok (get status permit))
        err-not-found
    )
)
