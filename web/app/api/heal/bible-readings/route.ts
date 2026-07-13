import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_bible_readings',
  defaultSort: 'day_number ASC',
  searchableFields: [],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
