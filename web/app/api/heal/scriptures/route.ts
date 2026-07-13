import { buildHealListHandler } from '../../../../lib/heal-list';
export const GET = buildHealListHandler({
  table: 'heal_scriptures',
  defaultSort: 'sort_order ASC, day_of_year ASC',
  searchableFields: ['reference', 'text', 'reflection_prompt'],
  filterableFields: ['is_published', 'slug', 'day_of_year', 'category'],
});
