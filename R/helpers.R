library(patchwork)

#' Variables for the raw variables section 
raw_variables <- list("Vertical Wind Speed" = "w" , 
                  "Horizontal Wind Speed (North)" = "v" , 
                  "Horizontal Wind Speed (East)" ="u",
                  "CO2" = "CO2",
                  "Water Vapor" = "H2O",
                  "Air Temperature" = "airtemp")
site <-  list("Silas Little" = "silas_little")
raw_data_files <- list("Combined 06/05/2018 and 01/19/2018" = "comb_2018-06-05_2018-01-19",
                      "Combined 06/06/2018 and 01/20/2018" = "comb_2018-06-06_2018-01-20")

#' Variables for the full data section  

full_var_times <- c("JD", "hrmm", "season", "timeofday")

full_variables <- list(
  "Julian Day" = "JD",
  "Photosynthetically active radiation" = "PPFD_in",
  "Hour : Minute" = "hrmm",
  "Air Temperature" = "TA",
  "Relative Humidity" = "RH",
  "Soil Moisture" = "Vol.W.C",
  "Soil Temperature" = "Soil.T",
  "Season" = "season",
  "Time of Day" = "timeofday",
  "Net Ecosystem Exchange" = "NEE"
)

#' Getting full name of variables 
#' @param varname A vector of shortened name of variables such as 'w'
#' @param varlist A list of variables and their original codes 
#' @return A vector of matched full names 
get_var_fullname <- function(varname, varlist){
  longname <- names(varlist)[which(varlist %in% varname)]
  return(longname) 
}

#' helper function to plot a whole bivariate plot or a bivariate plot animation through time.
#' param @input: list of input that user has chosen (given to us by shiny).
#' param @output: list of available ouput action (given to us by shiny).
#' param @variables: the variables to plot.
#' param @data: the data to work with.
#' param @season: which season to graph

plot_raw_data_bivariate <- function(input, output, variables, data, season){
  # pairplot 
  pairplot_summer <- reactiveValues(plot_slider = NULL, plot_full_graph = NULL)
  pairplot_winter <- reactiveValues(plot_slider = NULL, plot_full_graph = NULL)
  
  # Observe event for pushing one of the buttons
  observeEvent(input$load_time,{
    form_label_x <- names(variables)[which(variables == input$pairplot_xvar)] # label for x axis
    form_label_y <- names(variables)[which(variables == input$pairplot_yvar)] # label for y axis
    
    #
    frame <- as.double(input$frame) # what is the time frame
    num_frames = 24*frame # number of frames
    points_per_frame <- 3600/frame # represents the number of datapoints for each frame
    aval <- list()
    mod <- list()
    
    for(step in 1:num_frames){ # for each step 
      # get the data at each time step
      x <- pull(data, input$pairplot_xvar)[seq((step-1)*(points_per_frame) + 1, length = points_per_frame)]  
      y <- pull(data, input$pairplot_yvar)[seq((step-1)*(points_per_frame) + 1, length = points_per_frame)]
      aval[[step]] <-list(visible = FALSE,
                          name = paste0('h = ', round(step/frame, 3)),
                          x=x,
                          y=y)
    }
    aval[1][[1]]$visible = TRUE
    
    # create steps and plot all traces
    steps <- list()
    fig <- plot_ly()
    
    for (i in 1:num_frames) {
      fig <- add_markers(fig,x=aval[i][[1]]$x,  y=aval[i][[1]]$y, visible = aval[i][[1]]$visible, 
                         name = aval[i][[1]]$name, type = 'scatter', marker  = list(color = 'royalblue'), hoverinfo = 'name')
      name = " hours"
      if(i<=frame){
        name = " hour"
      }
      
      step <- list(args = list('visible', rep(FALSE, length(aval))), 
                   label =  paste0(round( i/frame, 2), name),
                   method = 'restyle')
      step$args[[2]][i] = TRUE  
      steps[[i]] = step 
    }  
    
    # add slider control to plot
    
    fig <- fig %>%
      layout(xaxis = list(title = form_label_x), yaxis = list(title = form_label_y),
             title = glue("{xaxis} vs {yaxis}", xaxis = form_label_x, yaxis = form_label_y),
             sliders = list(list(active = 0, currentvalue = list(prefix = "Frequency: "),
                                 steps = steps)))
    if(grepl(season, "summer")){
      pairplot_summer$plot_slider <- fig
    }
    else if(grepl(season, "winter")){
      pairplot_winter$plot_slider <- fig
    }
    
  })
  
  #plot whole graph
  observeEvent(input$load_all, {
    form_label_x <- names(variables)[which(variables == input$pairplot_xvar)] # label for x axis
    form_label_y <- names(variables)[which(variables == input$pairplot_yvar)] # label for y axis
    # getting data using pull()
    x <- pull(data,input$pairplot_xvar)
    y <- pull(data, input$pairplot_yvar)
  
    # adding the bivariate scatter plot and the trend line  
    if(grepl(season, "summer")){
      pairplot_summer$plot_full_graph <- ggplot(data = data, aes(x = !!sym(input$pairplot_xvar), y = !!sym(input$pairplot_yvar))) + theme_bw() + labs(y = form_label_y, x = form_label_x) +               
        geom_point(color = "orange", size = 1.5) 
    }
    else if(grepl(season, "winter")){
      pairplot_winter$plot_full_graph <- ggplot(data = data, aes(x = !!sym(input$pairplot_xvar), y = !!sym(input$pairplot_yvar))) + theme_bw() + labs(y = form_label_y, x = form_label_x) +               
        geom_point(color = "orange", size = 1.5)
    }
  })
  # render plots
  
  #summer graphs
  if(grepl(season, "summer")){
    #graph animation
    output$pairplot_summer_slider <- renderPlotly({
      suppressWarnings(pairplot_summer$plot_slider)
    })
    #graph bivariate plot
    output$pairplot_summer_full_graph <- renderPlot({
      suppressWarnings(pairplot_summer$plot_full_graph)
    })
  }
  #winter graphs
  else if(grepl(season, "winter")){
    #graph animation
    output$pairplot_winter_slider <- renderPlotly({
      suppressWarnings(pairplot_winter$plot_slider)
    })
    #graph bivariate plot
    output$pairplot_winter_full_graph <- renderPlot({
      suppressWarnings(pairplot_winter$plot_full_graph)
    })
  }
}

#' @title Out of sample prediction models using train/test split 
#' @param data Data of data.frame format
#' @param formula Regression formula class
#' @param split_prop Train-test split. Default 3/4 of the data set will be training 
oos_prediction <- function(data, formula, split_prop = 3/4){
  split <- initial_split(data, prop = split_prop)
  train <- linear_reg(mode = "regression") %>% set_engine("lm") %>% 
    fit(data = training(split), formula = formula)
  estimate <- predict(train, new_data = testing(split), type = "raw")
  interval <- predict(train, new_data = testing(split), type = "pred_int")
  truth <- testing(split)$NEE
  df <- cbind(estimate, interval, truth)
  annotation <- glue("RMSE: {rmse_val} \n Predictive R-squared: {rsq_val}", 
                     rmse_val = round(rmse_vec(truth = df$truth, estimate = df$estimate),2),
                     rsq_val = round(rsq_trad_vec(truth = df$truth, estimate = df$estimate),3))
  plot <- ggplot(data = df, aes(x = estimate, y = truth)) + geom_point(col = "steelblue", size = 2) + 
    geom_line() +
    geom_ribbon(aes(ymin = .pred_lower, ymax = .pred_upper), alpha = 0.3) + 
    stat_smooth(method = "lm", formula = y~x) + 
    labs(x = "Estimate", y = "Truth", title = "Out of Sample Prediction") + 
    annotate("text", x = min(df$estimate), y = max(df$truth), label = annotation, hjust = 0, size = 5) + theme_bw()
  return(plot)
} 

#' @title Evaluating lm fit on full data and evaluating 
#' @param data The data as data frame
#' @param formula Regression formula class 
#' @return A list of objects including model summary, fitting plots and residuals 
fit_eval <- function(data, formula){
  fit <- lm(formula = formula, data = data)
  mod_sum <- summary(fit) 
  
  # fitted values plot
  fitted <- fitted.values(fit)
  truth <- data$NEE
  df <- data.frame(fitted = fitted, truth = truth) %>% as.data.frame()
  annotation <- glue("AIC: {aic_val} \n Adj. R-squared: {rsq_val}", 
                     aic_val = round(AIC(fit),3),
                     rsq_val = round(mod_sum$adj.r.squared,3))
  fit_plot <- ggplot(df, aes(x = fitted, y = truth)) + geom_point(col = "steelblue", size = 2) + 
    stat_smooth(method = "lm", formula = y~x) + labs(x = "Estimate", y = "Truth", title = "Fitted values vs. True") +
    annotate("text", x = min(df$fitted), y = max(df$truth), label = annotation, hjust = 0, size = 5) +
    theme_bw()
  residuals <- resid(fit)
  out <- list(summary = mod_sum, fit_plot = fit_plot, residuals = residuals)
  return(out)
}

#' @title This function performs gapfilling and plotting of gapfilling variables  
#' @param data The data of interest
#' @param formula The model formula chosen to gapfill  
gap_filling <- function(data, formula){
  complete_data <- data %>% filter(!is.na(NEE))
  missing_data <- data %>% filter(is.na(NEE))
  model <- lm(formula = formula, data = complete_data)
  new_NEE <- predict(model, newdata = missing_data %>% select(-NEE))
  missing_data <- missing_data %>% mutate(NEE = new_NEE)
  combined <- rbind(missing_data, complete_data) %>% arrange(date)
  # conversion step 
  combined$NEE <- combined$NEE * (1/1000^2) * (12/44) * 60 * 30  
  neelab <- bquote("NEE"~g~C~m^-2~yr^-1)
  # boxplot of NEE distribution by day
  p1 <- ggplot(combined, aes(x = season, fill = timeofday, y = NEE )) + 
    geom_boxplot() + theme_bw() + scale_fill_brewer(palette = "Dark2") + 
    labs(x = "Season", y = neelab, fill = "Time of Day", 
         title = "Distribution of NEE by season and time of day")
  
  # barplot of total NEE
  p2 <- combined %>% group_by(season, timeofday) %>% summarize(NEE = sum(NEE)) %>% 
    ggplot(aes(y = NEE, x = season, fill = timeofday)) + geom_bar(stat = "identity", position = "dodge") +
    geom_text(aes(label = round(NEE,2), x = season, y = NEE/2), size = 4, position = position_dodge(width = 0.8), 
              vjust = 0, hjust = 0.5) + 
    theme_bw() + scale_fill_brewer(palette = "Dark2") +
    labs(x = "Season", y = neelab, fill = "Time of Day", 
         title = "Absolute NEE by season and time of day")
  # NEE by JD
  p3 <- combined %>% group_by(JD) %>% summarise(NEE = sum(NEE)) %>% ggplot(aes(x = JD, y = NEE)) + 
    geom_point(color = "orange") + theme_bw() + labs(y = neelab, x = "Julian Day") + 
    stat_smooth()
  
  total_title <- bquote("Total NEE:"~.(round(sum(combined$NEE),2))~g~C~m^-2~yr^-1)
  total_subtitle <- bquote("NEE in Winter Season:"~
                             .(round(sum(combined %>% filter(season == "W") %>% pull(NEE)),2))~g~C~m^-2~yr^-1~"; NEE in Growing Season"~
                             .(gs = round(sum(combined %>% filter(season == "GS") %>% pull(NEE)),2))~g~C~m^-2~yr^-1)
  
  plot <- ((p1 + theme(legend.position = "none")) + p2)/p3
  plot <- plot + plot_annotation(
    title = total_title,
    subtitle = total_subtitle,
    theme = theme(plot.title = element_text(size = 18), plot.subtitle = element_text(size = 15)))
  return(plot)
}
