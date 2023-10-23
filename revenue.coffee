import { query } from 'mu'

class MonthlySalesEntry
  constructor: (@month, @year, @amount) ->

  toJsonApi: () ->
    id: "#{@month}/#{@year}"
    type: 'monthly-sales-entries'
    attributes:
      month: @month
      year: @year
      amount: @amount

export default generateRevenueReport = (fromYear, untilYear) ->
  # Query makes UNION of
  # - all final invoices with at least 1 deposit invoice
  # - all final invoices without deposit invoices
  # - all deposit invoices
  # It takes the sum of all invoice amounts. For invoices with at least 1 deposit invoice,
  # the deposit invoice amout is retracted (since the deposit invoices are also
  # included in the UNION).
  # By making the invoice selection this way, we ensure to take each amount into account
  # in the month they were actually invoiced (since the month of the deposit invoice may
  # differ from the month of the final invoice).
  result = await query """
PREFIX p2poDocument: <https://purl.org/p2p-o/document#>
PREFIX p2poInvoice: <https://purl.org/p2p-o/invoice#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>

SELECT ?year ?month (SUM(?invoiceAmount) as ?amount)
WHERE {
  {
    {
      SELECT ?invoice ?depositAmount
      WHERE {
        ?invoice a p2poInvoice:E-FinalInvoice .
        {
          {
            SELECT ?invoice (SUM(?dArithmeticAmount) as ?depositAmount)
            WHERE {
              ?case ext:invoice ?invoice .
              ?case ext:depositInvoice ?depositInvoice .
              ?depositInvoice p2poInvoice:hasTotalLineNetAmount ?dAmount .
              OPTIONAL { ?invoice dct:type ?type . }
              BIND(IF(?type = p2poInvoice:E-CreditNote, ?dAmount * - 1, ?dAmount) as ?dArithmeticAmount)
            } GROUP BY ?invoice
          }
          UNION
          {
            SELECT ?invoice ?depositAmount
            WHERE {
              ?case ext:invoice ?invoice .
              FILTER NOT EXISTS { ?case ext:depositInvoice ?depositInvoice . }
              BIND(0.0 as ?depositAmount)
            }
          }
        }
      }
    }
    UNION
    {
      SELECT ?invoice ?depositAmount
      WHERE {
        ?invoice a p2poInvoice:E-PrePaymentInvoice .
        BIND(0.0 as ?depositAmount)
      }
    }
  }

  ?invoice p2poInvoice:dateOfIssue ?date ;
    p2poInvoice:hasTotalLineNetAmount ?netAmount ;
    p2poInvoice:invoiceNumber ?number .
  BIND(YEAR(?date) as ?year)
  FILTER (?year >= 2019 && ?year <= 2023)
  OPTIONAL { ?invoice dct:type ?type . }
  BIND(IF(?type = p2poInvoice:E-CreditNote, ?netAmount * - 1, ?netAmount) as ?arithmeticAmount)
  BIND(MONTH(?date) as ?month)
  BIND(?arithmeticAmount - ?depositAmount as ?invoiceAmount)
} GROUP BY ?year ?month ORDER BY ?year ?month
  """

  result.results.bindings.map (b) -> new MonthlySalesEntry(
    parseInt(b['month'].value),
    parseInt(b['year'].value),
    parseFloat(b['amount'].value)
  )
