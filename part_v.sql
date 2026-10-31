--PART V
--1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи удео?
--kreiramo view team_matches
CREATE OR REPLACE VIEW bootcamp.northern_star.team_matches AS
WITH sides AS (
SELECT match_id, season, matchday, kickoff_ts,
home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
venue,
home_goals AS goals_for, away_goals AS goals_against
FROM bootcamp.northern_star.matches WHERE status = 'played'
UNION ALL
SELECT match_id, season, matchday, kickoff_ts,
away_team_id, home_team_id, 'away',
away_goals, home_goals
FROM bootcamp.northern_star.matches WHERE status = 'played'
)
SELECT *,
CASE WHEN goals_for > goals_against THEN 'W'
WHEN goals_for = goals_against THEN 'D' ELSE 'L' END AS result,
CASE WHEN goals_for > goals_against THEN 3
WHEN goals_for = goals_against THEN 1 ELSE 0 END AS points
FROM sides;


with goals as(
    select season, team_id, sum(goals_for) as total_goals
    from team_matches
    where season = '2024/25'
    group by season, team_id
)
select g.team_id, team_name, total_goals, round(total_goals * 100 / sum(total_goals) over(partition by season), 2) as pct
from goals g join teams t on t.team_id = g.team_id 
order by pct desc

--Kingsbridge City ima najveci udeo, 7.6

--2.Која су три стадиона са највећом просечном посетом у сезони 2024/25?
select 
    s.stadium_name,
    round(avg(attendance),0) as avg_att,
    dense_rank() over(order by round(avg(attendance), 0) desc) as rn
from matches m join stadiums s on m.stadium_id = s.stadium_id
where season = '2024/25'
group by s.stadium_name
qualify rn <= 3

--Harbourside Park, Kingsbridge Stadium, Northport Arena

--3.За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи гол дао најраније?
with cte as(
    select m.match_id, me.team_id, player_id, kickoff_ts, me.event_id,
        lead(me.event_id) over(partition by me.team_id order by kickoff_ts) as next
    from matches m join match_events me on m.match_id = me.match_id
    where season = '2024/25' and event_type in ('goal', 'penalty_goal')
)
select c.team_id, c.player_id, team_name, first_name, last_name, kickoff_ts
from cte c join players p on c.player_id = p.player_id join teams t on t.team_id = c.team_id
where next is null
order by kickoff_ts
--klub koji je dao poslednji gol najranije je Elmsworth Wanderers

--4.За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену у односу на претходну домаћу утакмицу. Где је највећи пад?
select m.match_id, kickoff_ts, attendance, 
    attendance - lag(attendance) over(order by kickoff_ts) as diff
from matches m join teams t on m.home_team_id = t.team_id
where season = '2024/25' and team_name = 'Northport United' 
--najveci pad je kada uporedimo utakmice 2091 i 2110

--5.Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој утакмици по реду и ког датума је прешао 50 бодова?
with cte as (
    select match_id, kickoff_ts, 
        sum(points) over (order by kickoff_ts) as poeni,
        row_number() over (order by kickoff_ts) as rn
    from team_matches tm join teams t on tm.team_id = t.team_id
    where season = '2024/25' and team_name = 'Northport City' 
)
select match_id, kickoff_ts, rn
from cte
where poeni > 50
order by rn
limit 1
--match_id = 2210, utakmica je 21. po redu

