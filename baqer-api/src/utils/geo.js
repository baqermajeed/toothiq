/**
 * Ensures a GeoJSON Polygon is closed (first vertex equals last vertex).
 * MongoDB 2dsphere requires closed rings.
 * @param {object} polygon - GeoJSON Polygon { type: 'Polygon', coordinates: [[[lng,lat],...]] }
 * @returns {object} The polygon with closed rings (mutates in place)
 */
function ensurePolygonClosed(polygon) {
  if (!polygon || !polygon.coordinates || !Array.isArray(polygon.coordinates)) return polygon;
  for (const ring of polygon.coordinates) {
    if (!Array.isArray(ring) || ring.length < 3) continue;
    const first = ring[0];
    const last = ring[ring.length - 1];
    if (first[0] !== last[0] || first[1] !== last[1]) {
      ring.push([Number(first[0]), Number(first[1])]);
    }
  }
  return polygon;
}

/**
 * For future use: compute distance or dynamic fee based on zone/distance.
 */
function getDistanceFromPointToPolygon(lng, lat, polygon) {
  return null;
}

module.exports = {
  getDistanceFromPointToPolygon,
  ensurePolygonClosed,
};
