import { app, errorHandler } from 'mu'
import generateRevenueReport from './revenue'
import { appendFile } from 'node:fs/promises';

app.post '/revenue-reports', (req, res, next) ->
  currentYear = new Date().getFullYear()
  fromYear = req.body.data?.attributes?['from-year'] or (currentYear - 4)
  untilYear = req.body.data?.attributes?['until-year'] or currentYear
  entries = await generateRevenueReport(fromYear, untilYear)

  res.status(201).send(
    data: entries.map (e) -> e.toJsonApi()
  )

app.post '/error-notifications', (req, res, next) ->
  error = JSON.stringify(req.body.data)
  timestamp = new Date().toISOString().substring(0, "YYYY-MM-DD".length)
  logFile = "/share/#{timestamp}-errors.txt"
  await appendFile(logFile, "[#{error}],")
  res.status(204).send()

app.use(errorHandler)
