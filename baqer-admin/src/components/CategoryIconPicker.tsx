import { useRef } from 'react'

const categoryPresetModules = import.meta.glob('../assets/iconcategort/*.png', {
  eager: true,
  import: 'default',
}) as Record<string, string>

const brandPresetModules = import.meta.glob('../assets/brandicon/*.png', {
  eager: true,
  import: 'default',
}) as Record<string, string>

export type PresetCategoryIcon = {
  id: string
  label: string
  url: string
}

export type CategoryIconValue =
  | { kind: 'preset'; preset: PresetCategoryIcon }
  | { kind: 'custom'; file: File; previewUrl: string }

function mapPresetModules(modules: Record<string, string>): PresetCategoryIcon[] {
  return Object.entries(modules)
    .map(([path, url]) => {
      const fileName = path.split('/').pop() ?? path
      return {
        id: fileName,
        label: fileName.replace(/\.png$/i, ''),
        url,
      }
    })
    .sort((a, b) => a.label.localeCompare(b.label, 'ar'))
}

export const PRESET_CATEGORY_ICONS = mapPresetModules(categoryPresetModules)
export const PRESET_BRAND_ICONS = mapPresetModules(brandPresetModules)

export async function iconValueToFile(value: CategoryIconValue): Promise<File> {
  if (value.kind === 'custom') return value.file
  const response = await fetch(value.preset.url)
  const blob = await response.blob()
  return new File([blob], value.preset.id, { type: blob.type || 'image/png' })
}

type Props = {
  value: CategoryIconValue | null
  onChange: (value: CategoryIconValue | null) => void
  error?: string
  label?: string
  presets?: PresetCategoryIcon[]
}

export function CategoryIconPicker({
  value,
  onChange,
  error,
  label = 'أيقونة القسم *',
  presets = PRESET_CATEGORY_ICONS,
}: Props) {
  const fileInputRef = useRef<HTMLInputElement>(null)

  function selectPreset(preset: PresetCategoryIcon) {
    onChange({ kind: 'preset', preset })
  }

  function onCustomPicked(file: File | null) {
    if (!file) return
    onChange({ kind: 'custom', file, previewUrl: URL.createObjectURL(file) })
  }

  const previewUrl =
    value?.kind === 'preset' ? value.preset.url : value?.kind === 'custom' ? value.previewUrl : null

  return (
    <div className="category-icon-picker">
      <label className="field-label">{label}</label>
      {previewUrl ? (
        <div className="category-icon-preview">
          <img src={previewUrl} alt={label} />
        </div>
      ) : null}
      <div className="category-icon-grid">
        {presets.map((preset) => {
          const selected = value?.kind === 'preset' && value.preset.id === preset.id
          return (
            <button
              key={preset.id}
              type="button"
              className={`category-icon-option${selected ? ' is-selected' : ''}`}
              onClick={() => selectPreset(preset)}
              title={preset.label}
            >
              <img src={preset.url} alt={preset.label} />
            </button>
          )
        })}
      </div>
      <div className="category-icon-custom">
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          hidden
          onChange={(e) => onCustomPicked(e.target.files?.[0] ?? null)}
        />
        <button type="button" className="btn" onClick={() => fileInputRef.current?.click()}>
          رفع صورة جديدة
        </button>
        {value?.kind === 'custom' ? <span className="muted">تم اختيار صورة مخصصة</span> : null}
      </div>
      {error ? <div className="field-error">{error}</div> : null}
    </div>
  )
}
