import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_pages',
  defaultSort: 'id ASC',
  searchableFields: [],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
