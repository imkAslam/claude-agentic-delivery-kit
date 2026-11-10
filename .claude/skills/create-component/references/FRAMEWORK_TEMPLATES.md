# Framework templates

Each template shows typed props, the four data states and accessible markup. Replace `ItemList`, `Item` and `listItems` with the ticket's names. **Prefer the project's existing conventions over these.** Build from the project's UI-library components (`components/ui`) where they exist; the plain elements below only show the shape.

## React / Next.js (TypeScript)
```tsx
'use client'; // Next.js App Router: only when the component needs interactivity or browser APIs
import type { FC } from 'react';
import { useItems } from './use-items';            // wraps the generated client (see DATA_AND_STATE.md)

export interface ItemListProps { title: string; onSelect?: (id: string) => void }

export const ItemList: FC<ItemListProps> = ({ title, onSelect }) => {
  const { data, isLoading, error, refetch } = useItems();

  return (
    <section aria-labelledby="item-list-title" aria-busy={isLoading}>
      <h2 id="item-list-title">{title}</h2>
      {isLoading && <ItemListSkeleton />}
      {error && (
        <div role="alert">
          <p>{messageFor(error)}</p>
          <button type="button" onClick={() => refetch()}>Try again</button>
        </div>
      )}
      {data && data.length === 0 && <EmptyState action="Create item" />}
      {data && data.length > 0 && (
        <ul>
          {data.map((item) => (
            <li key={item.id}>
              <button type="button" onClick={() => onSelect?.(item.id)}>{item.name}</button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
};
```
Test skeleton (Testing Library + the project's runner):
```tsx
it('AC-ITM-5: shows the empty state when there are no items', async () => {
  server.use(mockListItems([]));                    // generated mock handler
  render(<ItemList title="Items" />);
  expect(await screen.findByText(/create item/i)).toBeInTheDocument();
});
```

## Vue 3 / Nuxt (`<script setup>`)
```vue
<script setup lang="ts">
const props = defineProps<{ title: string }>();
const emit = defineEmits<{ select: [id: string] }>();
const { data, pending, error, refresh } = useItems();   // composable over the generated client
</script>

<template>
  <section :aria-busy="pending" aria-labelledby="item-list-title">
    <h2 id="item-list-title">{{ props.title }}</h2>
    <ItemListSkeleton v-if="pending" />
    <div v-else-if="error" role="alert">
      <p>{{ messageFor(error) }}</p>
      <button type="button" @click="refresh()">Try again</button>
    </div>
    <EmptyState v-else-if="!data?.length" action="Create item" />
    <ul v-else>
      <li v-for="item in data" :key="item.id">
        <button type="button" @click="emit('select', item.id)">{{ item.name }}</button>
      </li>
    </ul>
  </section>
</template>
```

## Angular (standalone, signals)
```ts
import { Component, input, output, inject } from '@angular/core';
import { ItemsStore } from './items.store';

@Component({
  selector: 'app-item-list',
  standalone: true,
  template: `
    <section [attr.aria-busy]="store.loading()" aria-labelledby="item-list-title">
      <h2 id="item-list-title">{{ title() }}</h2>
      @if (store.loading()) { <app-item-list-skeleton /> }
      @else if (store.error()) {
        <div role="alert"><p>{{ store.errorMessage() }}</p>
          <button type="button" (click)="store.reload()">Try again</button></div>
      }
      @else if (store.items().length === 0) { <app-empty-state action="Create item" /> }
      @else {
        <ul>@for (item of store.items(); track item.id) {
          <li><button type="button" (click)="selected.emit(item.id)">{{ item.name }}</button></li>
        }</ul>
      }
    </section>`,
})
export class ItemListComponent {
  title = input.required<string>();
  selected = output<string>();
  store = inject(ItemsStore);
}
```

## Svelte 5 / SvelteKit
```svelte
<script lang="ts">
  let { title, onSelect }: { title: string; onSelect?: (id: string) => void } = $props();
  const items = useItems();            // store/rune wrapper over the generated client
</script>

<section aria-busy={items.loading} aria-labelledby="item-list-title">
  <h2 id="item-list-title">{title}</h2>
  {#if items.loading}<ItemListSkeleton />
  {:else if items.error}<div role="alert"><p>{messageFor(items.error)}</p><button type="button" onclick={items.reload}>Try again</button></div>
  {:else if items.data.length === 0}<EmptyState action="Create item" />
  {:else}<ul>{#each items.data as item (item.id)}<li><button type="button" onclick={() => onSelect?.(item.id)}>{item.name}</button></li>{/each}</ul>
  {/if}
</section>
```
For SvelteKit pages, load the data in `+page.server.ts` (`load`) and handle errors with `error()` plus `+error.svelte`.

## Solid
```tsx
import { Show, For, Switch, Match } from 'solid-js';
export function ItemList(props: { title: string; onSelect?: (id: string) => void }) {
  const [items, { refetch }] = useItems();   // createResource over the generated client
  return (
    <section aria-busy={items.loading} aria-labelledby="item-list-title">
      <h2 id="item-list-title">{props.title}</h2>
      <Switch>
        <Match when={items.loading}><ItemListSkeleton /></Match>
        <Match when={items.error}><div role="alert"><p>{messageFor(items.error)}</p><button type="button" onClick={refetch}>Try again</button></div></Match>
        <Match when={items()?.length === 0}><EmptyState action="Create item" /></Match>
        <Match when={items()}><ul><For each={items()}>{(item) => <li><button type="button" onClick={() => props.onSelect?.(item.id)}>{item.name}</button></li>}</For></ul></Match>
      </Switch>
    </section>
  );
}
```

## Astro (server-rendered, islands for interactivity)
```astro
---
import { listItems } from '../api/client';      // generated client, server side
const { title } = Astro.props as { title: string };
let items = [], failed = false;
try { items = (await listItems()).data; } catch { failed = true; }
---
<section aria-labelledby="item-list-title">
  <h2 id="item-list-title">{title}</h2>
  {failed ? <p role="alert">We couldn't load items. Refresh to try again.</p>
   : items.length === 0 ? <EmptyState action="Create item" />
   : <ul>{items.map((i) => <li>{i.name}</li>)}</ul>}
</section>
```
Put interactive parts in an island (`client:visible` / `client:idle`) that uses the matching framework template.
