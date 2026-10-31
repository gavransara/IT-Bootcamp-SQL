# IT Bootcamp - SQL project
## Sara Gavran

** This repository contains my SQL Project developed as part of the IT Bootcamp Data Engineer program.  **

## Technologies used
- **SQL** – Data querying and analysis
- **Databricks** – SQL execution environment
- **Visual Studio Code** – Code editing
- **Git & GitHub** – Version control


### fact_card table

Each row in fact_card table is linked to one card event (event_id) for a specific player in a specific match. This table enables us easier analysis of card events by players, clubs, referees and days.

Relationships :

 -event_id - unique for each card event, key of fact table
 -match_id - match identificator
 -date_key - dim_date.date_key (foreign kljuc)
 -team_id - dim_team.team_id (foreign kljuc)
 -player_id - dim_player.player_id (foreign kljuc)
 -referee_id - dim_referee.referee_id (foreign kljuc)