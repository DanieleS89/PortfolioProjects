# Explore
# Clean
# Manipulate
# Describe and summarize
# Visualize
# Analize


# creo una variabile con il dataset
bike_original_4 <- read.csv("Divvy_Trips_2019_Q4.csv", sep = ",")

# faccio vari controlli e carico le librerie necessarie
library(skimr)

head(bike_original_4)
glimpse(bike_original_4)

# analisi dei duplicati (R continua a crashare e non riesco a fare il chek dei duplicati)
# questa mostra un riscontro logico (TRUE, FALSE)
duplicated(tab_4)

# questa mostra tutti i valori duplicati (se ce ne sono)
tab_4[duplicated(tab_4), ]

# questa mostra tutti i valori della tabella tranne i duplicati (sconsigliato per grandi dataset)
tab_4[!duplicated(tab_4), ]

# stesso controllo dei duplicati, usando il pipe da tydiverse
tab_4 %>% distinct()

# per vedere i valori univoci presenti in una colonna
unique(tab_4$usertype)

# quante volte un determinato valore compare in una colonna
sum(tab_4$usertype == "Subscriber")

# in quale riga compare quel valore
which(tab_4$birthyear == "1984")

# stampare quella riga
subset(tab_4, usertype == "1984")

# che tipo di dati ci sono in quella colonna
class(tab_4$usertype)

# questo deriva dalla libreria skimr e fornisce un'analisi molto dettagliata riguardo a campi vuoti, valori univoci, ecc.
# dovrei salvare questi risultati in una variabile e inserirli nell'analisi dell' R Markdown
# in questo modo posso ripetere il controllo dopo le modifiche ed evidenziare le differenze
skim_without_charts(bike_original_4)

as_tibble(bike_original_4)

# controllo se ci sono valori "na"
colSums(is.na(bike_original_4))

# controllo se ci sono valori "na" oppure "null"
colSums(is.na(bike_original_4) | bike_original_4 == "")

# voglio dividere la colonna start_time in 3 colonne diverse: month, day, hour
# per fare questo devo installare lubridate
# install.packages("lubridate")
library(lubridate)

# Converti la colonna "start_time" in un oggetto di classe POSIXct
bike_original_4$start_time <- as.POSIXct(bike_original_4$start_time, format="%Y-%m-%d %H:%M:%S")

# Ora che "start_time" è un oggetto di classe POSIXct, posso creare le 3 colonne nuove secondo le indicazioni
bike_original_4$month <- month(bike_original_4$start_time, label = TRUE, abbr = FALSE)
bike_original_4$day <- weekdays(bike_original_4$start_time)

# qui devo creare la colonna hour e di nuovo convertirla in un oggetto POSIXct per poterlo modificare successivamente
bike_original_4$hour <- as.POSIXct(bike_original_4$start_time, format="%I:%M %p", tz = "UTC")


# arrotonda le ore per visualizzare solo 24 valori univoci nella colonna (il formato è ancora 2019-10-01 00:05:00)
bike_original_4$hour_rounded <- floor_date(bike_original_4$hour, unit = "hour")

# modifica il formato in 12:00 AM, ecc...
bike_original_4$hour_rounded <- strftime(bike_original_4$hour_rounded, format="%I:%M %p", tz = "UTC")

# Rimuovi le virgole e i decimali dalla colonna "tripduration"
bike_original_4$tripduration <- gsub(",", "", bike_original_4$tripduration)
bike_original_4$tripduration <- as.numeric(gsub("\\..*", "", bike_original_4$tripduration))

library(dplyr)
# Crea una nuova colonna "trip_d_minutes" espressa in minuti come numeri interi senza decimali
bike_original_4 <- bike_original_4 %>%
  mutate(trip_d_minutes = tripduration %/% 60)

# ora creo una tabella più piccola selezionando solo le colonne necessarie per l'analisi
tab_4 <- bike_original_4[c("usertype", "gender", "birthyear", "month", "day", "hour_rounded", "trip_d_minutes")]



