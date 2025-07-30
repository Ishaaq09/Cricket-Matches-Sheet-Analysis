# Cricket-Matches-Sheet-Analysis
This project focuses on extracting, transforming, and analyzing cricket match data from Cricsheet.org. The goal is to automate data collection, store it in an SQL database, perform deep analysis using SQL and Python, and visualize key insights through both Python plots and Power BI dashboards.

### Important Note
Due to GitHub's 100MB file size limit, this repository only includes the core Jupyter Notebook (`main.ipynb`) and documentation.

The full project folder (~1.5GB) contains:
- Extracted JSON data (`extracted_matches/`) ~1.3GB
- SQLite database (`cricsheet_analysis.db`) ~340MB

These files could not be pushed to GitHub directly.

If you want to run this project:
1. Clone the repo
2. Run the notebook cells step-by-step
3. The notebook will recreate all required files (download JSONs, parse data, create DB)

Feel free to reach out if you face issues.

### Project Objectives
1. Web scrape cricket data using Selenium
2. Parse and transform JSON files into structured data
3. Store match and ball-level data in SQLite
4. Perform SQL-based data analysis
5. Visualize trends using Python (matplotlib, seaborn)
6. Build an interactive Power BI dashboard

### Tools and Tech stacks:
1. Python (Selenium, Pandas, JSON)
2. SQLite (via sqlite3 connector)
3. SQL (20 queries)
4. Power BI Desktop
5. Matplotlib, Seaborn

### Web Scraping with Selenium
Aim: Navigate to cricsheet.org and download match data ZIPs for Test, ODI, T20, and IPL formats.

```
from selenium import webdriver
from selenium.webdriver.common.by import By 
import requests
import os
import time

# Navigating the driver to the website. 

driver = webdriver.Chrome()  
driver.get("https://cricsheet.org/matches/")

time.sleep(8) # Time for the website to fully load all the contents

zip_links = driver.find_elements(By.XPATH, '//a[contains(@href, ".zip")]') # finds all the elements that are .zip files
download_urls = [link.get_attribute('href') for link in zip_links] # stores the links contained in the elements
print(f"Total JSON links found: {len(download_urls)}")

data = 'cricsheet_json_files'
os.makedirs(data, exist_ok=True) # creating a folder for the JSON zip files to be downloaded

required_matches = ['tests_json.zip', 'odis_json.zip', 't20s_json.zip', 'ipl_json.zip'] # The zip files we need to download
filtered_urls = []
for url in download_urls:
    file_name = url.split("/")[-1] # gives name of the zip file
    if file_name in required_matches:
        filtered_urls.append(url)

len_of_filtered_urls = len(filtered_urls)
print(f"Downloaded {len_of_filtered_urls} files into '{data}' folder.")
driver.quit()
```

OUTPUT:
```Downloaded 4 files into 'cricsheet_json_files' folder.```

```
# this is for automating the downloading & storing part:

for url in filtered_urls:
    file_name = url.split("/")[-1]  
    full_path = os.path.join(data, file_name)
    
    # Only download if the .zip file doesn't exist already
    if not os.path.exists(full_path):
        response = requests.get(url)
        with open(full_path, "wb") as file:
            file.write(response.content)
        print(f"Downloaded: {file_name}")
    else:
        print(f"Already exists: {file_name}")
```

OUTPUT:
```
Already exists: tests_json.zip
Already exists: odis_json.zip
Already exists: t20s_json.zip
Already exists: ipl_json.zip
```

### Data Extraction and JSON Parsing
In this step, our aim is to extract downloaded .zip files and parse JSON files into structured DataFrames

```
import zipfile

extract_folder = 'extracted_matches'
os.makedirs(extract_folder,exist_ok = True)

for file in os.listdir("cricsheet_json_files"):
    if file.endswith(".zip"):
        zip_path = os.path.join("cricsheet_json_files", file)
        match_type = file.replace("_json.zip", "")
        output_path = os.path.join(extract_folder,match_type)
        os.makedirs(output_path, exist_ok=True)

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(output_path)
        print(f"Extracted: {file} to {output_path}")

import pandas as pd
import json
import os

def parse_ball_by_ball(folder_path, match_type_label):
    """
    Parses all JSON files in a folder and returns a ball-by-ball dataframe
    with batter, bowler, runs, wickets, and other delivery info.
    """
    delivery_data = []

    for file in os.listdir(folder_path):
        if file.endswith(".json"):
            filepath = os.path.join(folder_path, file)

            with open(filepath, "r") as f:
                match = json.load(f)

            info = match.get("info", {})
            match_date = info.get("dates", [""])[0]
            teams = info.get("teams", ["", ""])
            innings = match.get("innings", [])

            for inning_index, inning in enumerate(innings, start=1):
                batting_team = inning.get("team", "")
                overs = inning.get("overs", [])

                for over_data in overs:
                    over_number = over_data.get("over", -1)
                    deliveries = over_data.get("deliveries", [])

                    for ball_number, delivery in enumerate(deliveries, start=1):
                        batter = delivery.get("batter", "")
                        bowler = delivery.get("bowler", "")
                        non_striker = delivery.get("non_striker", "")

                        runs_batter = delivery.get("runs", {}).get("batter", 0)
                        runs_extras = delivery.get("runs", {}).get("extras", 0)
                        total_runs = delivery.get("runs", {}).get("total", 0)

                        dismissal_kind = None
                        player_out = None

                        if "wickets" in delivery:
                            for w in delivery["wickets"]:
                                dismissal_kind = w.get("kind", "")
                                player_out = w.get("player_out", "")

                        delivery_data.append({
                            "match_type": match_type_label,
                            "date": match_date,
                            "inning": inning_index,
                            "over": over_number,
                            "ball": ball_number,
                            "team": batting_team,
                            "batter": batter,
                            "bowler": bowler,
                            "non_striker": non_striker,
                            "runs_batter": runs_batter,
                            "runs_extras": runs_extras,
                            "total_runs": total_runs,
                            "dismissal_kind": dismissal_kind,
                            "player_out": player_out
                        })

    return pd.DataFrame(delivery_data)

test_path = os.path.join(extract_folder, "tests")
odi_path = os.path.join(extract_folder, "odis")
t20_path = os.path.join(extract_folder, "t20s")
ipl_path = os.path.join(extract_folder, "ipl")

df_test = parse_ball_by_ball(test_path, "Test")
df_odi = parse_ball_by_ball(odi_path, "ODI")
df_t20 = parse_ball_by_ball(t20_path, "T20")
df_ipl = parse_ball_by_ball(ipl_path, "IPL")

def matchSummary(folder_path, match_type_label):
    summary_data = []

    for file in os.listdir(folder_path):
        if file.endswith(".json"):
            filepath = os.path.join(folder_path, file)
            with open(filepath, "r") as f:
                match = json.load(f)

            info = match.get("info", {})
            date = info.get("dates", [""])[0]
            venue = info.get("venue", "")
            teams = info.get("teams", ["", ""])
            winner = info.get("outcome", {}).get("winner", "Draw/No result")
            toss_winner = info.get("toss", {}).get("winner", "")
            toss_decision = info.get("toss", {}).get("decision", "")
            outcome_by = info.get("outcome", {}).get("by", {})

            if "runs" in outcome_by:
                margin = outcome_by["runs"]
                margin_type = "runs"
            elif "wickets" in outcome_by:
                margin = outcome_by["wickets"]
                margin_type = "wickets"
            else:
                margin = None
                margin_type = None


            summary_data.append({
                "match_type": match_type_label,
                "date": date,
                "venue": venue,
                "team1": teams[0],
                "team2": teams[1],
                "winner": winner,
                "toss_winner": toss_winner,
                "toss_decision": toss_decision,
                "margin": margin,
                "margin_type": margin_type
            })

    return pd.DataFrame(summary_data)

```
OUTPUT:
```
Extracted: ipl_json.zip to extracted_matches\ipl
Extracted: odis_json.zip to extracted_matches\odis
Extracted: t20s_json.zip to extracted_matches\t20s
Extracted: tests_json.zip to extracted_matches\tests
```
1. We've created four ball-by-ball structured datasets for different match types(test,odi,ipl,t20).

2. We've also created match-level summaries dataset as well.

All these different dataframes for querying some useful insights from the JSON data.

### SQLite Database Creation & EDA Using Python:

```
import sqlite3

# connecting to the SQLite database using connector

conn = sqlite3.connect("cricsheet_analysis.db")
cursor = conn.cursor()

# Save each dataframe to a table in SQLite
df_test.to_sql("test_matches", conn, if_exists="replace", index=False)
df_odi.to_sql("odi_matches", conn, if_exists="replace", index=False)
df_t20.to_sql("t20_matches", conn, if_exists="replace", index=False)
df_ipl.to_sql("ipl_matches", conn, if_exists="replace", index=False)

print("All data inserted successfully into SQLite")
```

OUTPUT:
```
All data inserted successfully into SQLite
```

### SQL Queries for Insights:

query1: The top 10 batsmen by total runs in ODI matches:
```
query = """
SELECT batter, SUM(runs_batter) AS total_runs
FROM odi_matches
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;
"""

df_result = pd.read_sql_query(query, conn)
df_result
```

OUTPUT:

![image](https://github.com/user-attachments/assets/fd2bc75e-a67a-4378-979a-591f10a6bc5b)

query2: the top 10 bowlers who took the most wickets in T20 matches
```

query2 = """

SELECT 
bowler,
COUNT(*) AS wickets
FROM t20_matches
WHERE dismissal_kind IS NOT NULL
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

"""

df2_result = pd.read_sql_query(query2, conn)
df2_result

```

OUTPUT:

![image](https://github.com/user-attachments/assets/6f88d502-85a0-44bf-a724-065bbcbebfd3)

query 3: Team with the highest win percentage in Test cricket
```


query3 = """
SELECT 
    played.team,
    played.matches_played,
    won.matches_won,
    ROUND(won.matches_won * 100.0 / played.matches_played, 2) AS win_percentage
FROM 
    (
        SELECT team, COUNT(*) AS matches_played
        FROM (
            SELECT team1 AS team FROM test_summary
            UNION ALL
            SELECT team2 AS team FROM test_summary
        ) AS all_teams
        GROUP BY team
    ) AS played
LEFT JOIN 
    (
        SELECT winner AS team, COUNT(*) AS matches_won
        FROM test_summary
        WHERE winner IS NOT NULL
        GROUP BY winner
    ) AS won
ON played.team = won.team
ORDER BY win_percentage DESC;
"""
df3_result = pd.read_sql_query(query3, conn)
df3_result

```

OUTPUT:

![image](https://github.com/user-attachments/assets/8772017a-bfb8-40c3-8499-494863492462)

```
sns.barplot(data=df_result, y="batter", x="total_runs")
plt.title("Top 10 Run Scorers in ODIs")
plt.xlabel("Total Runs")
plt.ylabel("Batter")
plt.tight_layout()
plt.show()
```

OUTPUT:

![image](https://github.com/user-attachments/assets/9733dc1d-0918-4d2a-94bf-d8f88a25a1dc)

query4: Total number of centuries across all match types.
```
query4 = """
SELECT COUNT(*) AS total_centuries
FROM (
    SELECT batter, date, SUM(runs_batter) AS total_runs
    FROM (
        SELECT batter, date, runs_batter FROM test_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM odi_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM t20_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM ipl_matches
    ) AS all_data
    GROUP BY batter, date
    HAVING total_runs >= 100
) AS century_list;
"""

df4_result = pd.read_sql_query(query4, conn)
df4_result
```

OUTPUT:

![image](https://github.com/user-attachments/assets/3fcb1cf1-072d-4342-8917-94c030cda45d)

query5: Matches with the narrowest margin of victory.
```
df_test_summary = matchSummary(test_path,"tests")
df_odi_summary = matchSummary(odi_path,"odis")
df_t20_summary = matchSummary(t20_path,"t20s")
df_ipl_summary = matchSummary(ipl_path,"ipl")

df_match_summary = pd.concat([df_test_summary, df_odi_summary, df_t20_summary, df_ipl_summary])
df_match_summary.to_sql("match_summary", conn, if_exists="replace", index=False)


query5 = """
SELECT *
FROM match_summary
WHERE margin IS NOT NULL
ORDER BY margin ASC
LIMIT 5;
"""

df_result5 = pd.read_sql_query(query5, conn)
df_result5
```

OUTPUT:

![image](https://github.com/user-attachments/assets/7e4094a4-cdac-4e12-91a7-9727ed0f9f06)

query6: total matches in each match types(ipl,test,t20,odi)
```

query6 = """
SELECT match_type, COUNT(*) AS total_matches
FROM match_summary
GROUP BY match_type;
"""
df_result6 = pd.read_sql_query(query6, conn)
df_result6
```

OUTPUT:

![image](https://github.com/user-attachments/assets/4793cd81-a153-433e-a6d9-c1436b4a36be)

```
sns.barplot(data=df_result6, x="match_type", y="total_matches")
plt.title("Total Matches by Format")
plt.xlabel("Match Format")
plt.ylabel("Number of Matches")
plt.tight_layout()
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/1f61057c-7b6f-49f9-9f3a-8cd299d37c80)

query7: Toss decision frequency
```

query7 = """
SELECT match_type, toss_decision, COUNT(*) AS decision_count
FROM match_summary
GROUP BY match_type, toss_decision
ORDER BY match_type, decision_count DESC;

"""
df_result7 = pd.read_sql_query(query7, conn)
df_result7

```

OUTPUT:

![image](https://github.com/user-attachments/assets/b2582aba-32d9-4f48-8054-b4049c9a7f2e)

```
plt.figure(figsize=(8,5))
sns.barplot(data=df_result7, x="match_type", y="decision_count", hue="toss_decision")
plt.title("Toss Decisions by Format")
plt.xlabel("Match Format")
plt.ylabel("Decision Count")
plt.legend(title="Toss Decision")
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/855a0c82-c89e-4ac9-8c4c-d3fa11da30ee)

query8: most frequent toss winners

```

query8 = """
SELECT toss_winner, COUNT(*) AS toss_wins
FROM match_summary
GROUP BY toss_winner
ORDER BY toss_wins DESC
LIMIT 10;
"""
df_result8= pd.read_sql_query(query8, conn)
df_result8
```

OUTPUT:

![image](https://github.com/user-attachments/assets/693c3c80-5d91-495f-bbff-8662a4be743d)

```
sns.barplot(data=df_result8, y="toss_winner", x="toss_wins")
plt.title("Top 10 Toss-Winning Teams")
plt.xlabel("Toss Wins")
plt.ylabel("Team")
plt.tight_layout()
plt.show()
```

OUTPUT:

![image](https://github.com/user-attachments/assets/0756c52f-2ed0-469b-badf-d38a5d09b7ee)

query9: most victorious teams overall

```

query9 = """
SELECT winner, COUNT(*) AS total_wins
FROM match_summary
WHERE winner IS NOT NULL AND winner != 'Draw/No result'
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 10;
"""
df_result9= pd.read_sql_query(query9, conn)
df_result9
```

OUTPUT:

![image](https://github.com/user-attachments/assets/d176425f-e87a-4404-b597-9f852495a1db)

```
sns.barplot(data=df_result9, y="winner", x="total_wins")
plt.title("Top 10 Match-Winning Teams")
plt.xlabel("Match Wins")
plt.ylabel("Team")
plt.tight_layout()
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/296ac115-e584-4f96-a0bc-3539789d56f6)

query10: venues hosting most matches

```

query10 = """
SELECT venue, COUNT(*) AS matches_hosted
FROM match_summary
GROUP BY venue
ORDER BY matches_hosted DESC
LIMIT 10;
"""
df_result10 = pd.read_sql_query(query10, conn)
df_result10
```

OUTPUT:

![image](https://github.com/user-attachments/assets/8401c317-373f-416d-8675-e2575c02762a)

```
sns.barplot(data=df_result10, y="venue", x="matches_hosted")
plt.title("Top 10 Venues by Number of Matches Hosted")
plt.xlabel("Match Count")
plt.ylabel("Venue")
plt.tight_layout()
plt.show()

```
OUTPUT:

![image](https://github.com/user-attachments/assets/234f4f60-398d-4ad6-9d36-aac0f67ec541)

query11: most sixes by a batter (T20 matches)

```

query11 = """
SELECT batter, COUNT(*) AS sixes
FROM t20_matches
WHERE runs_batter = 6
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;
"""
df_result11 = pd.read_sql_query(query11, conn)
df_result11

```

OUTPUT:

![image](https://github.com/user-attachments/assets/eda40cb8-2f4d-40d6-90a6-8f1ca9114603)

```
sns.barplot(data=df_result11, y="batter", x="sixes")
plt.title("Top 10 Six-Hitters in T20 Matches")
plt.xlabel("Total Sixes")
plt.ylabel("Batter")
plt.tight_layout()
plt.show()

```

OUTPUT:

![image](https://github.com/user-attachments/assets/581964c7-ac12-475a-9bfa-6d8a21fe9a7d)

query12: most fours by a batter (ODI matches)

```

query12 = """
SELECT batter, COUNT(*) AS fours
FROM odi_matches
WHERE runs_batter = 4
GROUP BY batter
ORDER BY fours DESC
LIMIT 10;
"""
df_result12 = pd.read_sql_query(query12, conn)
df_result12
```

OUTPUT:

![image](https://github.com/user-attachments/assets/5bf9a8b7-5556-471f-8696-a141dfc20475)

```
sns.barplot(data=df_result12, y="batter", x="fours")
plt.title("Top 10 Four-Hitters in ODI Matches")
plt.xlabel("Total Fours")
plt.ylabel("Batter")
plt.tight_layout()
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/c126ab18-3625-48c8-b4db-b2561b3c7ab1)

query13: bowlers with most dot balls (IPL)

```

query13 = """
SELECT bowler, COUNT(*) AS dot_balls
FROM ipl_matches
WHERE total_runs = 0
GROUP BY bowler
ORDER BY dot_balls DESC
LIMIT 10;
"""
df_result13 = pd.read_sql_query(query13, conn)
df_result13

```

OUTPUT:

![image](https://github.com/user-attachments/assets/64f20b57-0c6d-473c-a7d5-d6c94d2da7d3)

```
sns.barplot(data=df_result13, y="bowler", x="dot_balls")
plt.title("Top 10 Dot Ball Bowlers in IPL")
plt.xlabel("Dot Balls")
plt.ylabel("Bowler")
plt.tight_layout()
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/be54ab95-4378-427e-88f9-7a9a2213b3fc)

query14: players with most dismissals (all match types)

```

query14 = """
SELECT player_out, COUNT(*) AS dismissals
FROM (
    SELECT player_out FROM test_matches
    UNION ALL
    SELECT player_out FROM odi_matches
    UNION ALL
    SELECT player_out FROM t20_matches
    UNION ALL
    SELECT player_out FROM ipl_matches
)
WHERE player_out IS NOT NULL
GROUP BY player_out
ORDER BY dismissals DESC
LIMIT 10;
"""
df_result14 = pd.read_sql_query(query14, conn)
df_result14
```
OUTPUT:

![image](https://github.com/user-attachments/assets/e331e3f2-c076-4879-a70a-47dbf6acb1af)

query15: total runs scored by each team (ODI)

```

query15 = """
SELECT team, SUM(total_runs) AS total_team_runs
FROM odi_matches
GROUP BY team
ORDER BY total_team_runs DESC
LIMIT 10;
"""
df_result15 = pd.read_sql_query(query15, conn)
df_result15
```
OUTPUT:

![image](https://github.com/user-attachments/assets/7cebde4a-ef81-4202-8e24-58879a09b973)

```
sns.barplot(data=df_result15, y="team", x="total_team_runs")
plt.title("Top 10 Teams by Total Runs in ODI Matches")
plt.xlabel("Total Runs")
plt.ylabel("Team")
plt.tight_layout()
plt.show()
```
OUTPUT:

![image](https://github.com/user-attachments/assets/2adf4927-b6b6-4966-8aa6-94e0ac8d6d8b)

query16: team that won most tosses and also won the match (ODI)

```

query16 = """
SELECT toss_winner, toss_decision, COUNT(*) AS toss_match_wins
FROM match_summary
WHERE toss_winner = winner
GROUP BY toss_winner, toss_decision
ORDER BY toss_match_wins DESC;
"""
df_result16 = pd.read_sql_query(query16, conn)
df_result16
```
OUTPUT:

![image](https://github.com/user-attachments/assets/0c844e4b-8bc0-4e21-8c54-9ce4a1958e87)

query17: number of matches decided by wickets

```

query17 = """
SELECT COUNT(*) AS wickets_victories
FROM match_summary
WHERE margin_type = 'wickets';
"""
df_result17 = pd.read_sql_query(query17, conn)
df_result17
```
OUTPUT:

![image](https://github.com/user-attachments/assets/09ef0dba-a3f2-48cb-94dc-fd0d51e8baad)

query18: number of matches decided by runs

```

query18 = """
SELECT COUNT(*) AS runs_victories
FROM match_summary
WHERE margin_type = 'runs';
"""
df_result18 = pd.read_sql_query(query18, conn)
df_result18
```
OUTPUT:

![image](https://github.com/user-attachments/assets/6ed15bfe-0ce8-4efd-833d-65a213f6ff7e)

query19: total boundaries (4s and 6s) in IPL

```

query19 = """
SELECT 
    SUM(CASE WHEN runs_batter = 4 THEN 1 ELSE 0 END) AS total_fours,
    SUM(CASE WHEN runs_batter = 6 THEN 1 ELSE 0 END) AS total_sixes
FROM ipl_matches;

"""
df_result19 = pd.read_sql_query(query19, conn)
df_result19
```
OUTPUT:

![image](https://github.com/user-attachments/assets/fc10e9b0-35c4-4985-8453-4932df1f3ce9)

query20: batters with most 50+ scores (All match types)

```

query20 = """
SELECT batter, COUNT(*) AS fifties_or_more
FROM (
    SELECT batter, date, SUM(runs_batter) AS total_runs
    FROM (
        SELECT batter, date, runs_batter FROM test_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM odi_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM t20_matches
        UNION ALL
        SELECT batter, date, runs_batter FROM ipl_matches
    )
    GROUP BY batter, date
    HAVING total_runs >= 50
)
GROUP BY batter
ORDER BY fifties_or_more DESC
LIMIT 10;

"""
df_result20 = pd.read_sql_query(query20, conn)
df_result20
```
OUTPUT:

![image](https://github.com/user-attachments/assets/66e65d3e-6f62-408c-a44f-e94a31de1688)

### Power BI Dashboard:

Finally, we're creating an interactive visual dashboard using Power BI.

1. For the first step, we're saving the DataFrames to csv files. We have now saved 6 csv files saved for the dashboard visualizations.

2. Used stacked column charts, bar graphs, pie charts

Player performance trends (batting, bowling):

![image](https://github.com/user-attachments/assets/9ef302a0-3206-44ce-8722-07f21a8cae5f)

Match outcomes by teams:

![image](https://github.com/user-attachments/assets/56a50df5-84eb-4729-b935-49876a899781)

Win/loss analysis across different formats:

![image](https://github.com/user-attachments/assets/1ababe22-88bc-45a4-a69a-4fdced9e0fd3)

Comparative statistics of teams and players:

![image](https://github.com/user-attachments/assets/44629ec7-6b6d-40fd-92d0-6340d19cdf68)


### sql queries and schema creation:

These are two sql files, of which should one should contain the 20 sql queries we used, the other is the schema of the 6 tables.


