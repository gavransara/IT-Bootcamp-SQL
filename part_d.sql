--PART G
--Направите звездасту шему.

--1. У part_d.sql направите и напуните табеле.
--dim_team -Сви клубови из teams
create or replace table dim_team as select * from teams

select * from dim_team

--dim_date - Календар - као на часу
CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d)

select * from dim_date

--dim_player - Сви играчи из players, плус непознати члан са player_id = -1
create or replace table dim_player as select * from players
insert into dim_player(player_id) values(-1)

select * from dim_player

--dim_referee - Сви судије из referees
create or replace table dim_referee as select * from referees

select * from dim_referee

--fact_card - Један ред по картону (yellow_card, second_yellow, red_card) из match_events
--У fact_card ставите: event_id, match_id, date_key, team_id, player_id, referee_id и врсту картона. Догађаји са играчем кога нема у players добијају player_id = -1.
create or replace table fact_card as 
select event_id, m.match_id, date(kickoff_ts) as date_key, team_id, 
    case when p.player_id is not null then p.player_id else -1 end as player_id, 
    referee_id,
    me.event_type as card_type
from matches m join match_events me on m.match_id = me.match_id left join players p on p.player_id = me.player_id
where event_type in ('yellow_card', 'second_yellow', 'red_card')

select * from fact_card

--2.Упитом покажите да fact_card има исто редова колико има картонских догађаја.
select 
(select count(*) from fact_card) - (select count(*) from match_events where event_type in ('yellow_card', 'second_yellow', 'red_card')) as diff

--3.Колико картона има player_id = -1?
select count(*) as unknown_players
from fact_card
where player_id = -1

--4. У README.md, у пар реченица опишите модел: шта је један ред у fact_card, који су кључеви (везе) и зашто мислите да картони имају своју табелу чињеница
--dodacemo u README.md sledece :
--Svaki red u fact_card je vezan za jedan kartonski dogadjaj (event_id) odredjenom igracu na odredjenoj utakmici. Pomocu ovakve fact tabele, omogucena je jednostavnija analiza dogadjaja dodele kartona po igracima, klubovima, sudijama i vremenu.
--Koje su veze :
 --event_id - jedinstven za svaki kartonski dogadjaj, kljuc fact tabele
 --match_id - identifikator utakmice
 --date_key - dim_date.date_key (strani kljuc)
 --team_id - dim_team.team_id (strani kljuc)
 --player_id - dim_player.player_id (strani kljuc)
 --referee_id - dim_referee.referee_id (strani kljuc)
