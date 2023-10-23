import { app, errorHandler } from 'mu'
import generateRevenueReport from './revenue'

app.post '/revenue-reports', (req, res, next) ->
  currentYear = new Date().getFullYear()
  fromYear = req.body.data?.attributes?['from-year'] or (currentYear - 4)
  untilYear = req.body.data?.attributes?['until-year'] or currentYear
  entries = await generateRevenueReport(fromYear, untilYear)

  res.status(201).send(
    data: entries.map (e) -> e.toJsonApi()
  )

app.use(errorHandler)
