import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_praise',
  defaultSort: 'sort_order ASC NULLS LAST, day_of_year ASC NULLS LAST',
  searchableFields: ['title', 'lyrics', 'reflection', 'description'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
