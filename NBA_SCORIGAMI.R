### NBA SCORIGAMI ###

library(hoopR)
library(tidyverse)
library(plotly)

create_gami <- function(season, low = 50, high = 200, by = 10, color_low = '#f0a70a', color_high = '#f00a0a'){
  sched <- load_nba_schedule(seasons = season) %>% select(id, attendance, game_date, home_name, home_score, away_name, away_score, home_winner) %>% filter(home_score != 0 | away_score != 0)
  
  num_games = nrow(sched)
  
  gami <- sched %>% mutate(winning_score = ifelse(home_score>away_score, home_score, away_score), losing_score = ifelse(home_score<away_score, home_score, away_score)) %>% mutate(margin = winning_score - losing_score, home_winner = ifelse(home_score==winning_score, TRUE, FALSE)) %>% group_by(winning_score, losing_score) %>% summarize(count = n()) 
  
  num_scores = nrow(gami)
  impossible = tibble()
  for (i in 0:300) {
    temp = tibble(
      w_score = i,
      l_score = i:300
    )
    impossible = bind_rows(impossible, temp)
  }
  
  high_count <- gami %>% filter(count==max(gami$count))
  
  lwin = min(gami$winning_score) - 1
  llos = min(gami$losing_score) - 1
  mwin = max(gami$winning_score) + 1
  mlos = max(gami$losing_score) + 1
  
  if(length(season)>1){
    subtitle = sprintf(
      '%d-%d seasons, %d games with %d unique scores',
      season[1] - 1,
      season[length(season)],
      num_games,
      num_scores
    )
  } else{
    subtitle=sprintf(
      '%d-%d season, %d games with %d unique scores',
      season-1,
      season,
      num_games,
      num_scores
    )
  }
  
  ggplot(data=gami) + 
    aes(
      x=winning_score, 
      y=losing_score, 
      fill = count
    ) +
    
    geom_tile(
      height=1, 
      width=1
    ) + 
    
    scale_fill_gradient(
      low = color_low, 
      high= color_high
    ) + 
    
    theme_bw() + 
    
    geom_tile(
      data=impossible, 
      aes(
        x=w_score, 
        y=l_score
      ), 
      fill='darkgray', 
      alpha=.5
    ) +
    
    labs(
      y='Losing Score', 
      x = 'Winning Score', 
      fill='COUNT', 
      subtitle=subtitle
    ) +
    
    coord_fixed(
      ylim = c(high, low), 
      xlim = c(low, high), 
      expand = FALSE
    ) +
    
    scale_x_continuous(
      breaks = seq(from = low, to = high, by = by)
    ) +
    
    scale_y_continuous(
      breaks=seq(from=low, to=high, by=by)
    )
  
}


#------------------------------------------------------------------------------#

library(shiny)
library(colourpicker)

ui <- fluidPage(
  titlePanel('NBA SCORIGAMI'),
  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId = "season", label = "Select Season Range", min = 2002, 
                  max = 2022, value = c(2005,2010)),
      
      colourInput("low_col", "Select Low Color", "orange"),
      colourInput("high_col", "Select High Color", "red")
      
      #selectInput(inputId = 'low_color', label = 'Low Color', choices = colors, selected = 'orange'),
      #selectInput(inputId = 'high_color', label = 'High Color', choices = colors, selected = 'red')
    ),
    mainPanel(
      plotOutput(outputId = 'gami', width = 815, height = 815)
    )
    
  )
)

#------------------------------------------------------------------------------#

server <- function(input, output, session) {
  
  output$gami <- renderPlot({
    create_gami(c(input$season[1]:input$season[length(input$season)]), color_low = input$low_col, color_high = input$high_col)
    
  })
}



shinyApp(ui = ui, server = server)






