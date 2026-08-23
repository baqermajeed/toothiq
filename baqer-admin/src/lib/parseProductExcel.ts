import * as XLSX from 'xlsx'

export type SpreadsheetParseResult = {
  columns: string[]
  rows: Record<string, string>[]
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

function normalizeHeader(value: string) {
  return value.trim().replace(/\s+/g, ' ').toLowerCase()
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

export function parseSpreadsheet(buffer: ArrayBuffer): SpreadsheetParseResult {
  const workbook = XLSX.read(buffer, { type: 'array', cellDates: true })
  const firstSheetName = workbook.SheetNames[0]
  if (!firstSheetName) return { columns: [], rows: [] }
  const sheet = workbook.Sheets[firstSheetName]
  const rawRows = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, {
    defval: '',
    raw: false,
  })
  const columns = rawRows.length > 0 ? Object.keys(rawRows[0]) : []
  const rows = rawRows.map((row) => {
    const mapped: Record<string, string> = {}
    for (const col of columns) {
      mapped[col] = cellToString(row[col])
    }
    return mapped
  })
  return { columns, rows }
}

export function rowHasAnyValue(row: Record<string, string>) {
  return Object.values(row).some((value) => value.trim() !== '')
}
