-- Part B - извештај о сезони 2024/25
--1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа домаћина, нерешених и победа гостију
with stats as(
    select match_id, home_goals + away_goals as goals, 
        case when home_goals > away_goals then 'home_win'
            when home_goals < away_goals then 'away_win'
            when home_goals = away_goals then 'draw' end as result
    from matches
    where season = '2024/25'
)
select count(*) as num_matches, sum(goals) as total_goals, 
        round(avg(goals), 2) as avg_goals,
        round(sum(case when result = 'home_win' then 1 else 0 end) * 100 / count(*), 2) as pct_home_win,
        round(sum(case when result = 'away_win' then 1 else 0 end) * 100 / count(*), 2) as pct_away_win,
        round(sum(case when result = 'draw' then 1 else 0 end) * 100 / count(*), 2) as pct_draw
from stats

--Broj utakmica : 380
--Broj golova : 1092
--Prosecan br golova po utakmici : 2.87
--Udeo pobeda domacina : 41.32
--Udeo pobeda gostiju : 33.68
--Udeo izjednacenih utakmica : 25

--2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у
--сваком месецу. Који месец се издваја?
select month(kickoff_ts) as month, year(kickoff_ts) as year,
    count(match_id) as num_matches, sum(home_goals + away_goals) as total_goals,
    round(sum(home_goals + away_goals) / count(match_id), 2) as avg_goals
from matches
where season = '2024/25'
group by month, year

-- month	year	num_matches	total_goals	avg_goals
-- 8	    2024	28	            99	        3.54
-- 9	    2024	32	            78	        2.44
-- 10	    2024	30	            102	        3.4
-- 11	    2024	37	            96	        2.59
-- 12	    2024	52	            145	        2.79
-- 1	    2025	51	            137	        2.69 
-- 2	    2025	40	            119	        2.98
-- 3	    2025	40	            113	        2.83
-- 4	    2025	40	            124	        3.1
-- 5	    2025	30	            79	        2.63
--decembar se izdvaja kao mesec sa najvise utakmica, najvise postignutih golova, dok je avgust mesec sa najvecim prosekom

--3.Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и
--утакмица без публике.
select stadium_name, 
        round(avg(attendance), 2) as avg_att, 
        round(avg(attendance * 100 /capacity),2) as capacity,
        sum(case when attendance is null then 1 else 0 end) as no_info, 
        sum(case when attendance = 0 then 1 else 0 end) as no_att
from matches m join stadiums s on s.stadium_id = m.stadium_id
where season = '2024/25'
group by stadium_name


--4.Судије: за сваког судију број утакмица и картони по утакмици.
select m.referee_id, r.referee_name, count(distinct m.match_id) as num_matches,
     round(count(me.event_id) / count(distinct m.match_id), 2) as num_cards
from matches m left join match_events me on m.match_id = me.match_id and event_type in ('yellow_card', 'second_yellow', 'red_card') left join referees r on r.referee_id = m.referee_id
where season = '2024/25'
group by m.referee_id, r.referee_name

--kartoni po utakmici : prosecan broj kartona po utakmici

--5.Играчи: пет најбољих стрелаца и пет најбољих асистената.
--Strelci :
select 
    me.player_id,
    p.first_name,
    p.last_name,
    sum(case when me.event_type = 'penalty_goal' then 1 else 0 end) as num_penalty,
    sum(case when me.event_type = 'goal' then 1 else 0 end) as num_clear_goal,
    count(me.event_id) as no_goals
from match_events me 
    join matches m on (me.team_id = m.home_team_id or me.team_id = m.away_team_id) and me.match_id = m.match_id join players p on p.player_id = me.player_id
where m.season = '2024/25' and me.event_type in ('goal', 'penalty_goal') 
group by me.player_id, p.first_name, p.last_name
order by no_goals desc

-- Mattéo O'Brien	4	30	34 --num_penalty, num_clear_goal, no_goals
-- Leo	Marsh	4	28	32
-- José	Muñoz	3	21	24
-- Marko	Stanković	4	13	17
-- Leo	Marsh	1	15	16
-- Ben	Bennett	1	14	15

select me.related_player_id,
        p.first_name,
        p.last_name,
        count(me.event_id) as no_assistance
from matches m 
join match_events me on m.match_id = me.match_id and (me.team_id = m.home_team_id or me.team_id = m.away_team_id)
join players p on me.related_player_id = p.player_id
where m.season = '2024/25' and me.related_player_id is not null
and me.event_type = 'goal'
group by me.related_player_id, p.first_name, p.last_name
order by no_assistance desc

-- 19	Pablo	Fernández	9
-- 111	Filip	Petrović	7
-- 49	Lucas	Pereira	7
-- 341	Eirik	Solberg	7
-- 45	Mikkel	Nielsen	6

--6.Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица
--чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без
--тренера), са упитима који их проналазе.
select me.*, p.player_id
from match_events me left join players p on me.player_id = p.player_id
where p.player_id is null

--nepostojeci igrac sa player_id = 99999 je dobio dva puta zuti karton; taj id ne postoji u tabeli players

select m.match_id, (home_goals - count(distinct me.event_id)) as diff
from matches m left join match_events me on m.match_id = me.match_id and me.event_type in ('goal', 'penalty_goal', 'own_goal') and m.home_team_id = me.team_id
group by m.match_id, home_goals
having diff > 0
union all
select m.match_id, (away_goals - count(distinct me.event_id)) as diff
from matches m left join match_events me on m.match_id = me.match_id and me.event_type in ('goal', 'penalty_goal', 'own_goal') and m.away_team_id = me.team_id
group by m.match_id, away_goals
having diff > 0


select * from matches where match_id = 2227 --ukupno 4 gola, 3 za domacina, 1 za goste
select * from match_events where match_id = 2227 --imamo 3 gola