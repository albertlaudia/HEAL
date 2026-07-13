import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_quotes',
  defaultSort: 'sort_order ASC, day_of_year ASC',
  searchableFields: ['text', 'attribution', 'source'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
