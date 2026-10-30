--Part A
--1. Колико утакмица је одиграно у фебруару 2025?
select count(*) as num_games
from matches
where month(kickoff_ts) = 2 and year(kickoff_ts) = 2025 and status = 'played'
--40

--2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?
select stadium_name, capacity, team_id
from stadiums s left join teams t on s.stadium_id = t.stadium_id
order by capacity desc
--Najveci kapacitet ima stadion National Stadium, a najveci stadion nekog kluba je Harbourside Park

--3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?
select count(player_id) as num_players
from players 
where nationality = 'Serbia'
--42

--4. Колико утакмица је завршено резултатом 1:1?
select count(match_id) as num_draw_1_1
from matches
where home_goals = 1 and away_goals = 1
--94

--5.Колика је просечна посета по сезони?
select season, round(avg(attendance), 2) as avg_season_att
from matches
group by season
-- season	avg_season_att
-- 2023/24	24252.95
-- 2024/25	24199.49


--6.Колико голова је дато из пенала по сезони?
select season, count(event_id) as penalty_goals
from match_events me join matches m on m.match_id = me.match_id
where event_type = 'penalty_goal'
group by season
-- season	penalty_goals
-- 2023/24	104
-- 2024/25	109


--7.Колико различитих играча је дало бар један гол у сезони 2024/25?
select count(distinct player_id) as num_players
from matches m join match_events me on m.match_id = me.match_id 
where season = '2024/25' and event_type in ('goal', 'penalty_goal', 'own_goal')
--racunala sam i autogolove
--330

--8.Који судија је највише пута судио утакмице клуба Northport United?
select r.referee_id, r.referee_name, count(*) as num_matches
from matches m join teams t1 on t1.team_id = m.home_team_id join teams t2 on t2.team_id = m.away_team_id join referees r on r.referee_id = m.referee_id
where t1.team_name = 'Northport United' or t2.team_name = 'Northport United'
group by r.referee_id, r.referee_name
order by num_matches desc
--Peter Lindgren, sudio 9 utakmica

--9.Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један пенал, дат или промашен?
select m.referee_id, referee_name, round(count(me.event_id) * 100 / count(m.match_id), 2) as pct_penalty
from matches m left join match_events me on m.match_id = me.match_id and event_type in ('penalty_miss', 'penalty_goal') left join referees r on r.referee_id = m.referee_id
where season = '2024/25'
group by m.referee_id, referee_name
order by pct_penalty desc
--udeo utakmica u kojima je dosudjen penal - od svih utakmica, koliko njih ima dosudjen penal
--Peter Lindgren, 56%

--10.Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на
--полувремену? Рачунајте и домаће и гостујуће утакмице.

--view sa sredjenim podacima u manager_spells za team_id = 7 :
create or replace view manager_spells_clean as (
    select * from manager_spells
    where spell_id not in (27,28,29)
)

with cte as(
    select m.home_team_id as team_id, ms.spell_id, ms.manager_name, home_goals as team_goals, away_goals as opponent_goals
    from matches m  join manager_spells_clean ms on ms.team_id = m.home_team_id and date(kickoff_ts) between ms.start_date and coalesce(ms.end_date, '9999-12-31')
    where home_goals_ht < away_goals_ht
    union all
    select m.away_team_id as team_id, ms.spell_id, ms.manager_name, away_goals as team_goals, home_goals as opponent_goals
    from matches m  join manager_spells_clean ms on ms.team_id = m.away_team_id and date(kickoff_ts) between ms.start_date and coalesce(ms.end_date, '9999-12-31')
    where home_goals_ht > away_goals_ht
)
select 
    spell_id, manager_name,
    sum(case when team_goals > opponent_goals then 3
            when team_goals = opponent_goals then 1
            else 0 end) as points
from cte
group by spell_id, manager_name
order by points desc
--Zoran Tosic, 18 poena

