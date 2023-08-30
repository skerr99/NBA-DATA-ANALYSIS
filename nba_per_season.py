import pandas as pd
from bs4 import BeautifulSoup as bs
import requests
from rich import print


# 1950 - 2023
# {#year, #champions, #mvp, roy, dpoy, mip, 6moy, scoring_champ, east_first, west_first}
def get_season_info(year):
    url = f'https://www.basketball-reference.com/leagues/NBA_{year}.html'

    req = requests.get(url)

    soup = bs(req.content, 'lxml')

    links = soup.find_all('p')
    season = {}
    season['Year'] = int(year)
    #print(len(links))

    for x in links:
        #print(x.text)
        if 'League Champion' in x.text:
            season['Champion'] = x.text.split(':')[1][1:]
        if 'PPG Leader' in x.text:
            season['PPG Leader'] = x.text.split(':')[1][1:].split('(')[0][:-1]

    try:
        east = soup.find_all('table', attrs = {'id' : 'confs_standings_E'})
        season['EC RS Winners'] = east[0].find('a').text

    except:

        east = soup.find('table', attrs = {'id' : 'divs_standings_E'})
        split_up = east.text.split('\n')
        best_teams = []
        wins = []
        for row in split_up:
            if '*' in row:
                row = row.split('*')
                best_teams.append(row[0])
                wins.append(int(row[1][:2]))
        best_ind = wins.index( max(wins) )
        best_team = best_teams[best_ind]

        season['EC RS Winners'] = best_team


    try:
        west = soup.find_all('table', attrs = {'id' : 'confs_standings_W'})
        season['WC RS Winners'] = west[0].find('a').text

    except:
        west = soup.find('table', attrs = {'id' : 'divs_standings_W'})
        split_up = west.text.split('\n')
        best_teams = []
        wins = []
        for row in split_up:
            if '*' in row:
                row = row.split('*')
                best_teams.append(row[0])
                wins.append(int(row[1][:2]))
        best_ind = wins.index( max(wins) )
        best_team = best_teams[best_ind]

        season['WC RS Winners'] = best_team

    award_names = ['mvp', 'roy', 'dpoy']
    
    for award in award_names:

        award_url = f'https://www.basketball-reference.com/awards/{award}.html'
        req = requests.get(award_url)
        soup = bs(req.content, 'lxml')
        year_code = str(f'{int(year) - 1}-{str(year)[2:]}')
        tab = soup.find('table').text.split('\n')

            
        for row in tab:
            year_code_tab = str(row[:7])

            if year_code_tab == year_code:
                winner = row.split('NBA')[1].split('(V)')[0][:-1]
                season[award.upper()] = winner
                break
            else:
                season[award.upper()] = None
                    
                    
    return season



seasons_list = []

for x in range(1980,2024):
    seasons_list.append( get_season_info(  x ) )

df = pd.DataFrame(seasons_list)
df.to_csv('/Users/seankerr/Downloads/nba_per_season.csv')
