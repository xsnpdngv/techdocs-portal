# Sequence diagrams

These are rendered server-side by **PlantUML** (`plantuml_markdown`
extension). The portal image ships a local `plantuml` binary so no
external server is required.

## Login flow

```plantuml format="svg"
@startuml
title Login flow

actor User
participant "Web UI" as UI
participant "API gateway" as GW
participant "Auth service" as Auth
database "User DB" as DB

User -> UI : enter credentials
UI -> GW : POST /login
GW -> Auth : verify(credentials)
Auth -> DB : lookup user
DB --> Auth : user record
Auth --> GW : JWT
GW --> UI : 200 OK + cookie
UI --> User : redirect to /home
@enduml
```

## C4 container view

```plantuml format="svg"
@startuml
!include <C4/C4_Container>

LAYOUT_WITH_LEGEND()

Person(user, "Customer")
System_Boundary(myservice, "my-service") {
    Container(api, "API", "Go", "Exposes REST endpoints")
    Container(worker, "Worker", "Go", "Processes background jobs")
    ContainerDb(db, "PostgreSQL", "RDBMS", "Stores domain data")
}

Rel(user, api, "Uses", "HTTPS")
Rel(api, db, "Reads/writes")
Rel(api, worker, "Enqueues jobs", "AMQP")
Rel(worker, db, "Reads/writes")
@enduml
```

You can also use the `::uml:: ... ::end-uml::` block syntax — both are
supported by `plantuml-markdown`.
