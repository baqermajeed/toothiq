import * as XLSX from 'xlsx'

export type SpreadsheetParseResult = {
  columns: string[]
  rows: Record<string, string>[]
  headerRowNumber: number
}

function cellToString(value: unknown): string {
  if (value == null) return ''
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10)
  }
  return String(value).trim()
}

export const SYSTEM_FIELDS = [
  { key: 'name', label: 'الاسم', required: true },
  { key: 'price', label: 'السعر', required: true },
  { key: 'description', label: 'الوصف', required: false },
  { key: 'categoryName', label: 'القسم / التصنيف من الملف', required: false },
  { key: 'brandName', label: 'البراند من الملف', required: false },
  { key: 'expiryDate', label: 'تاريخ النفاذ', required: false },
] as const

export type SystemFieldKey = (typeof SYSTEM_FIELDS)[number]['key']

const ALIASES: Record<SystemFieldKey, string[]> = {
  name: ['الاسم', 'اسم', 'اسم المنتج', 'المادة', 'المنتج', 'الماده', 'name', 'item', 'product'],
  price: ['السعر', 'سعر', 'سعر المفرد', 'سعر الوحدة', 'price', 'unit price'],
  description: ['الوصف', 'وصف', 'الملاحظات', 'ملاحظات', 'description', 'notes'],
  categoryName: ['القسم', 'التصنيف', 'تصنيف', 'قسم', 'category', 'section'],
  brandName: ['البراند', 'العلامة', 'ماركة', 'brand'],
  expiryDate: ['تاريخ النفاذ', 'النفاذ', 'انتهاء الصلاحية', 'تاريخ الانتهاء', 'expiry', 'expire'],
}

const ALL_ALIASES = Object.values(ALIASES).flat()

function normalizeHeader(value: string) {
  return value.trim().replace(/\s+/g, ' ').toLowerCase()
}

function looksLikeEmptyHeader(value: string) {
  return !value || /^(__)?empty(_\d+)?(__)?$/i.test(value)
}

function looksLikeNumericOnly(value: string) {
  return /^\d+([.,]\d+)?$/.test(value)
}

function isLikelyHeaderLabel(value: string) {
  const n = normalizeHeader(value)
  if (!n || looksLikeEmptyHeader(n) || looksLikeNumericOnly(n)) return false
  return ALL_ALIASES.some((alias) => n === normalizeHeader(alias) || n.includes(normalizeHeader(alias)))
}

export function guessMapping(columns: string[]): Record<SystemFieldKey, string> {
  const mapping = {
    name: '',
    price: '',
    description: '',
    categoryName: '',
    brandName: '',
    expiryDate: '',
  } satisfies Record<SystemFieldKey, string>

  for (const field of SYSTEM_FIELDS) {
    const aliases = ALIASES[field.key]
    const match = columns.find((col) => {
      const n = normalizeHeader(col)
      return aliases.some((alias) => n === normalizeHeader(alias) || n.includes(normalizeHeader(alias)))
    })
    if (match) mapping[field.key] = match
  }
  return mapping
}

function headerScore(cells: unknown[]): number {
  let score = 0
  for (const cell of cells) {
    const text = cellToString(cell)
    if (!text) continue
    if (isLikelyHeaderLabel(text)) score += 12
    else if (!looksLikeNumericOnly(text) && /[^\d.,]/.test(text)) score += 2
  }
  return score
}

function uniqueHeaders(rawHeaders: string[]): string[] {
  const used = new Map<string, number>()
  return rawHeaders.map((raw, index) => {
    let name = raw.trim()
    if (looksLikeEmptyHeader(name) || looksLikeNumericOnly(name)) {
      name = `عمود ${index + 1}`
    }
    const count = used.get(name) ?? 0
    used.set(name, count + 1)
    return count > 0 ? `${name} (${count + 1})` : name
  })
}

function findHeaderRowIndex(matrix: unknown[][]): number {
  const scanLimit = Math.min(matrix.length, 25)
  let bestIndex = -1
  let bestScore = 0
  for (let i = 0; i < scanLimit; i += 1) {
    const score = headerScore(matrix[i] || [])
    if (score > bestScore) {
      bestScore = score
      bestIndex = i
    }
  }
  if (bestIndex >= 0 && bestScore >= 12) return bestIndex

  for (let i = 0; i < scanLimit; i += 1) {
    const filled = (matrix[i] || []).map(cellToString).filter(Boolean)
    const textCells = filled.filter((value) => !looksLikeNumericOnly(value))
    if (textCells.length >= 2) return i
  }
  return 0
}

export function parseSpreadsheet(buffer: ArrayBuffer): SpreadsheetParseResult {
  const workbook = XLSX.read(buffer, { type: 'array', cellDates: true })
  const firstSheetName = workbook.SheetNames[0]
  if (!firstSheetName) return { columns: [], rows: [], headerRowNumber: 1 }
  const sheet = workbook.Sheets[firstSheetName]
  const matrix = XLSX.utils.sheet_to_json<unknown[]>(sheet, {
    header: 1,
    defval: '',
    raw: false,
    blankrows: false,
  })
  if (!Array.isArray(matrix) || matrix.length === 0) {
    return { columns: [], rows: [], headerRowNumber: 1 }
  }

  const headerIndex = findHeaderRowIndex(matrix)
  const headerCells = (matrix[headerIndex] || []).map(cellToString)
  let lastFilled = headerCells.length - 1
  while (lastFilled > 0 && !headerCells[lastFilled]) lastFilled -= 1
  const slicedHeaders = headerCells.slice(0, lastFilled + 1)
  const columns = uniqueHeaders(slicedHeaders)
  if (columns.length === 0) return { columns: [], rows: [], headerRowNumber: headerIndex + 1 }

  const rows = matrix.slice(headerIndex + 1).map((line) => {
    const mapped: Record<string, string> = {}
    columns.forEach((col, index) => {
      mapped[col] = cellToString(line?.[index])
    })
    return mapped
  })

  return {
    columns,
    rows,
    headerRowNumber: headerIndex + 1,
  }
}

export function rowHasAnyValue(row: Record<string, string>) {
  return Object.values(row).some((value) => value.trim() !== '')
}
