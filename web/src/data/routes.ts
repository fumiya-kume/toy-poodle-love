/**
 * Predefined taxi tour routes data
 */

import { RouteSpot } from '../types/scenario';

/**
 * Location with geographic coordinates
 */
export interface LocationData {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
}

/**
 * Predefined route with spots and metadata
 */
export interface PredefinedRoute {
  id: string;
  routeName: string;
  description: string;
  spots: RouteSpot[];
  locations: LocationData[];
}

/**
 * Tokyo Station to Asakusa route
 * A scenic taxi tour through central Tokyo's historic and cultural landmarks
 */
export const tokyoStationToAsakusaRoute: PredefinedRoute = {
  id: 'tokyo-station-asakusa',
  routeName: 'Tokyo Station → Asakusa Course',
  description: 'A journey from Tokyo Station through historic landmarks to Asakusa',
  spots: [
    {
      name: 'Tokyo Station',
      type: 'start',
      description: 'Historic red-brick railway station, a landmark of modern Tokyo',
      point: 'Marunouchi Building, restored to its original 1914 appearance',
    },
    {
      name: 'Imperial Palace Outer Garden (Nijubashi Bridge)',
      type: 'waypoint',
      description: 'Former Edo Castle grounds, now the residence of the Emperor',
      point: 'Famous double bridge (Nijubashi) with beautiful pine trees',
    },
    {
      name: 'Nihonbashi Bridge',
      type: 'waypoint',
      description: 'Historic bridge marking the center of old Edo and kilometer zero of Japan',
      point: 'Original starting point of the Five Routes of the Edo period',
    },
    {
      name: 'Akihabara Electric Town',
      type: 'waypoint',
      description: 'World-famous electronics and anime/manga culture district',
      point: 'From post-war electronics market to modern otaku paradise',
    },
    {
      name: 'Kappabashi Kitchenware Street',
      type: 'waypoint',
      description: 'Wholesale district for kitchen tools and restaurant supplies',
      point: 'Famous for realistic plastic food samples (sampuru)',
    },
    {
      name: 'Asakusa Kaminarimon Gate',
      type: 'destination',
      description: 'Iconic thunder gate entrance to Senso-ji Temple',
      point: 'Giant red lantern and guardian statues, symbol of old Tokyo',
    },
  ],
  locations: [
    {
      name: 'Tokyo Station (Start)',
      address: '1 Chome Marunouchi, Chiyoda City, Tokyo',
      latitude: 35.681236,
      longitude: 139.767125,
    },
    {
      name: 'Imperial Palace Outer Garden (Nijubashi Bridge)',
      address: '1-1 Kokyo Gaien, Chiyoda City, Tokyo',
      latitude: 35.685175,
      longitude: 139.755486,
    },
    {
      name: 'Nihonbashi Bridge',
      address: '1 Chome Nihonbashi, Chuo City, Tokyo',
      latitude: 35.683662,
      longitude: 139.773714,
    },
    {
      name: 'Akihabara Electric Town',
      address: '1 Chome Sotokanda, Chiyoda City, Tokyo',
      latitude: 35.698683,
      longitude: 139.773073,
    },
    {
      name: 'Kappabashi Kitchenware Street',
      address: '3-18-2 Matsugaya, Taito City, Tokyo',
      latitude: 35.712291,
      longitude: 139.787134,
    },
    {
      name: 'Asakusa Kaminarimon Gate (Goal)',
      address: '2-3-1 Asakusa, Taito City, Tokyo',
      latitude: 35.710719,
      longitude: 139.796635,
    },
  ],
};

/**
 * All available predefined routes
 */
export const predefinedRoutes: PredefinedRoute[] = [
  tokyoStationToAsakusaRoute,
];

/**
 * Get a predefined route by ID
 */
export function getRouteById(id: string): PredefinedRoute | undefined {
  return predefinedRoutes.find(route => route.id === id);
}

/**
 * Get all route summaries for selection UI
 */
export function getRouteSummaries(): Array<{ id: string; name: string; description: string }> {
  return predefinedRoutes.map(route => ({
    id: route.id,
    name: route.routeName,
    description: route.description,
  }));
}
