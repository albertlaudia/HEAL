import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_essays',
  defaultSort: 'sort_order ASC, day_of_year ASC',
  searchableFields: ['title', 'body', 'subtitle'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
