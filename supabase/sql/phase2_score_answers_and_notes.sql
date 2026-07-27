-- Run in Supabase SQL editor (Phase 2 / Phase 3 prerequisites).
-- Unique constraint for score_answers upsert by shop_id
alter table score_answers
  add constraint score_answers_shop_id_unique unique (shop_id);

-- Notes counter RPC (idempotent if already applied)
create or replace function increment_notes_count(shop_id_input uuid)
returns void as $$
  update shops set notes_count = coalesce(notes_count, 0) + 1
  where id = shop_id_input;
$$ language sql;
