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
select team_id, player_id, kickoff_ts
from cte
where next is null
--delimicno uradjeno, nasli smo koji igrac u kom klubu je dao i kada poslednji gol u sezoni

