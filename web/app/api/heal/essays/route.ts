import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_essays',
  defaultSort: 'day_of_year ASC NULLS LAST',
  searchableFields: ['title', 'body', 'subtitle'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
