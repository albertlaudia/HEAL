import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_prayers',
  defaultSort: 'id ASC',
  searchableFields: ['title', 'body', 'attribution'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
