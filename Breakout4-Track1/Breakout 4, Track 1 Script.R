############################################################################## #

# Visualizing Networks w/ Overlapping Groups
# Adam J. Saffer | asaffer@umn.edu | @SafferPHD

############################################################################## #

# 1. LOAD PACKAGES  ====

install.packages(c('googledrive', 'googlesheets4', 'readxl',
                   'dplyr', 'igraph', 'ggplot2', 'ggraph', 'RColorBrewer',))

library(googledrive)
library(googlesheets4)
library(readxl)

library(tidyverse)
library(dplyr)
library(igraph)
library(ggplot2)
library(ggraph)
library(RColorBrewer)

# 2. LOAD DATA ====

## 2.1 Load the nodes and attributes assigned to them. 

### 2.1.2 Here is how you can do it with readxl: 

nodes = read_excel("noRth 2021 Breakout 4, Track 1 Data.xlsx", 
                   sheet = "Nodes", 
                   col_names = TRUE, 
                   trim_ws = TRUE, 
                   range = 'A1:Q126')

### 2.1.2 Here is how you can do it with googlesheets4: 

nodes = read_sheet('https://docs.google.com/spreadsheets/d/1z-NcAnCqS8DQYUdWJMyVFWBcXcoZXdmdL5aMi3YHZzQ/edit?usp=sharing',
                   sheet = "Nodes",
                   range = "A1:Q126",
                   col_names = TRUE,
                   col_types = NULL,
                   na = "",
                   trim_ws = TRUE,
                   skip = 0,
                   .name_repair = "unique")

# Have a look at the object:

head(nodes, 5)

## 2.2 Now we should bring in the nodes' ties

### 2.2.2 Here is how you can do it with readxl: 

ties = read_excel("noRth 2021 Breakout 4, Track 1 Data.xlsx", 
                   sheet = "Ties")

### 2.1.2 Here is how you can do it with googlesheets4: 

ties = read_sheet('https://docs.google.com/spreadsheets/d/1z-NcAnCqS8DQYUdWJMyVFWBcXcoZXdmdL5aMi3YHZzQ/edit?usp=sharing',
                  sheet = "Ties",
                  range = "A1:B511",
                  col_names = TRUE,
                  col_types = NULL,
                  na = "",
                  trim_ws = TRUE,
                  skip = 0,
                  .name_repair = "unique")

# Have a look at the object:

head(ties, 5)

# 3. CREATE NETWORK GRAPH ====

## 3.1 Here we use igraph to create a graph object

g = graph_from_data_frame(ties %>%
                            select(FROM, TO), 
                          directed = TRUE, 
                          vertices = nodes)

# Have a look at the graph object 

g

# 4. VISUALIZE: BASIC GRAPH ====

# 4.1 We want to start with a very basic plot of the graph:

plot(g)

# 4.2 Now we can add some more parameters to make it look more appealing

plot(g, 
     layout = layout.fruchterman.reingold(g),
     rescale = TRUE, 
     axes = FALSE,
     frame = FALSE, 
     asp = 8.5/10,
     margin = -0.15,
     main = "noRth 2021: Breakout 4, Track 1 Network",
     sub = "Note: Basic network plot.",
     cex.sub=.5,
     col.sub="blue",
     #Vertex
     vertex.label = "",
     vertex.color = "blue", 
     vertex.size = 2,
     vertex.frame.color = "#ffffff",
     vertex.shape = "circle",
     vertex.label.color="black",
     vertex.label.family = "Helvetica", #typeface
     vertex.label.font = 1, #font: 1 plain, 2 bold, 3 italic, 4 bold italic, 5 symbol
     vertex.label.cex = .5, #font size 
     vertex.label.degree=-pi/2,
     vertex.label.dist=.25, 
     usearrows = TRUE,
     edge.arrow.size = .25,
     edge.arrow.width = .25, 
     edge.lty = 1, # Line type
     edge.width = .25)


# 5. VISUALIZE: IN/OUT-GROUP TIES ====

# 5.1 Setting up data to identify the issues orgs work on. 

# The survey asked: "Of the 8 issues listed here, what is the most important 
# issues your organization works on related to government reform?" Respondents
# could select two issues from the list of eight. 

# 5.1.1 Reshaping the survey response (wide) to a suitable format (long)

# 5.1.2 Create an object to hold the specific data needed

issue_workon = nodes %>%
  select(ID, 
         OrgIssue1, 
         OrgIssue2)

head(issue_workon, 5)

# 5.1.3 Pivot_longer (dplyr) will allow use to reshape quickly. 

issues_workon.l= issue_workon %>% 
  pivot_longer(
    cols = c("OrgIssue1", "OrgIssue2"), 
    names_to = "ORDER", 
    values_to = "ISSUE") %>%
  filter(!is.na(ISSUE))

head(issues_workon.l, 5)

# 5.1.4 Relabel the acronyms in ISSUE to have the full name 

issues_workon.l$ISSUE[issues_workon.l$ISSUE=="CSR"] = "Civil service reforms"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="GG"] = "Good governance"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="GLC"] = "Reform of government linked companies"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="IPMR"] = "Indigenous persons and minority reform"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="IR"] = "Institutional reforms"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="LR"] = "Labor rights"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="MD"] = "Media orgs"
issues_workon.l$ISSUE[issues_workon.l$ISSUE=="SCT"] = "Security in country"

# 5.1.5 Create object that contains the within group ties.

within_group_edges <- issues_workon.l %>%
  split(.$ISSUE) %>%
  map_dfr(function (grp) {
    id2id <- combn(grp$ID, 2)
    data_frame(FROM = id2id[1,],
               TO = id2id[2,],
               ISSUE = unique(grp$ISSUE))
  })

head(within_group_edges, 5)

# 5.1.6 Create a new object for within group ties

ties %>% add_column(ISSUE = NA, .after = "TO")

ties.within <- bind_rows(ties, within_group_edges)

head(ties.within, 5)

ties.within = ties.within %>%
  filter(!is.na(ISSUE))

head(ties.within, 5)

# 5.1.6 Create a graph with the within group ties

g.within <- graph_from_data_frame(ties.within, 
                           directed = FALSE)

ggraph(g.within) +
  geom_edge_link(aes(color = ISSUE), alpha = 0.5) + # different edge color per group
  geom_node_point(size = 7, shape = 21, stroke = 1,
                  fill = 'white', color = 'black') +
  geom_node_text(aes(label = name)) +  # "name" is automatically generated from the node IDs in the edges
  theme_void()

# 6. VISUALIZE: OVERLAPPING GROUPS ====

# 6.1.1  Create object identifying the nodes within groups

workon_group_id = issues_workon.l %>%
  select(ID, 
         ISSUE)

# 6.1.1  Additional objects necessary for plotting

group_ids <- lapply(workon_group_id %>% split(.$ISSUE), function(grp) { grp$ID })
group_color <- brewer.pal(length(group_ids), 'Set3') # ?brewer.pal
group_color_fill <- paste0(group_color, '20') # the fill gets an additional alpha value for transparency:

# 6.2.1  Visualize overlapping groups

plot(simplify(g),  
     #LAYOUT
     layout=layout.fruchterman.reingold(g), 
     rescale = TRUE, 
     axes = FALSE,
     frame = FALSE, 
     main = "noRth 2021: Breakout 4, Track 1 Network",
     sub = "Note: Sociogram with overlapping groups.",
     cex.font = 3.25,
     cex.sub=.25,
     col.sub="blue",
     asp=9.5/10, 
     margin=-0.175,
     #GROUPS 
     mark.groups = group_ids,
     mark.col = group_color_fill,
     mark.border = group_color,
     #NODES
     vertex.color= "grey",
     vertex.frame.color = "#ffffff",
     vertex.shape = "circle",
     vertex.size = 2, 
     vertex.label = "",
     vertex.label.color="black",
     vertex.label.family = "Helvetica", #typeface
     vertex.label.font = 1, #font: 1 plain, 2 bold, 3 italic, 4 bold italic, 5 symbol
     vertex.label.cex = .85, #font size 
     vertex.label.degree=-pi/2,
     vertex.label.dist=.25,
     #EDGES
     usearrows = TRUE,
     edge.arrow.size = .25,
     edge.arrow.width = .25, 
     edge.lty = 1, # Line type
     edge.width = .25
)

legend(-1.75, 1, legend = names(group_ids), xpd = TRUE,
       col = group_color_fill, bty = "n",
       pch = 15, pt.cex = 1, cex = .8,
       text.col = "black", horiz = FALSE, ncol = 1, y.intersp = .7)


# 7. RESOURCES/REFERENCES 

# https://www.r-bloggers.com/2018/05/visualizing-graphs-with-overlapping-node-groups/

# END # ====