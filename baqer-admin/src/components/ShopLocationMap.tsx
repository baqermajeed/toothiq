import { useMemo } from 'react'
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import iconUrl from 'leaflet/dist/images/marker-icon.png'
import shadowUrl from 'leaflet/dist/images/marker-shadow.png'

const defaultIcon = L.icon({
  iconUrl,
  shadowUrl,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  shadowSize: [41, 41],
})
L.Marker.mergeOptions({ icon: defaultIcon })

function MapClickHandler({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng)
    },
  })
  return null
}

type Props = {
  lat: number
  lng: number
  onChange: (lat: number, lng: number) => void
  height?: number
}

/** خريطة تفاعلية: انقر لتحديد موقع المحل (lat, lng). */
export function ShopLocationMap({ lat, lng, onChange, height = 260 }: Props) {
  const validLat = Number.isFinite(lat) ? lat : 33.3152
  const validLng = Number.isFinite(lng) ? lng : 44.3661
  const center = useMemo<[number, number]>(() => [validLat, validLng], [validLat, validLng])

  return (
    <div
      style={{
        height,
        width: '100%',
        borderRadius: 8,
        overflow: 'hidden',
        border: '1px solid var(--border)',
      }}
    >
      <MapContainer center={center} zoom={13} style={{ height: '100%', width: '100%' }} scrollWheelZoom>
        <TileLayer attribution="&copy; OpenStreetMap" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <Marker position={[validLat, validLng]} draggable eventHandlers={{ dragend: (e) => {
          const m = e.target
          const p = m.getLatLng()
          onChange(p.lat, p.lng)
        } }} />
        <MapClickHandler onPick={onChange} />
      </MapContainer>
    </div>
  )
}
