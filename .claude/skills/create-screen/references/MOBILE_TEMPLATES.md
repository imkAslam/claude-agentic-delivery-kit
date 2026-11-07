# Mobile templates

## Expo / React Native (TypeScript)
```tsx
import { FlatList, RefreshControl, Text, Pressable, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';   // or the expo-router equivalent
import { useItems } from '../api/use-items';                                   // query hook over the generated client
import { useNetworkState } from '../lib/network';

type Props = NativeStackScreenProps<RootStackParamList, 'Items'>;

export function ItemsScreen({ navigation }: Props) {
  const { data, isLoading, isRefetching, error, refetch } = useItems();
  const { isOffline } = useNetworkState();

  if (isLoading) return <ItemsSkeleton />;
  if (error && !data) return <ErrorState message={messageFor(error)} onRetry={refetch} />;

  return (
    <SafeAreaView style={{ flex: 1 }}>
      {isOffline && <OfflineBanner accessibilityLiveRegion="polite" />}
      <FlatList
        data={data}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
        ListEmptyComponent={<EmptyState action="Create item" onPress={() => navigation.navigate('NewItem')} />}
        renderItem={({ item }) => (
          <Pressable accessibilityRole="button" accessibilityLabel={`Open ${item.name}`}
                     onPress={() => navigation.navigate('Item', { id: item.id })}
                     style={{ minHeight: 44, justifyContent: 'center' }}>
            <Text>{item.name}</Text>
          </Pressable>
        )}
      />
    </SafeAreaView>
  );
}
```
Test skeleton (React Native Testing Library):
```tsx
it('AC-ITM-5: shows the empty state', async () => {
  server.use(mockListItems([]));
  render(<ItemsScreen navigation={nav} route={route} />);
  expect(await screen.findByText(/create item/i)).toBeOnTheScreen();
});
```

## Flutter (Dart)
```dart
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);                 // provider over the generated client
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: SafeArea(
        child: items.when(
          loading: () => const ItemsSkeleton(),
          error: (e, _) => ErrorState(message: messageFor(e), onRetry: () => ref.invalidate(itemsProvider)),
          data: (list) => list.isEmpty
              ? EmptyState(action: 'Create item', onPressed: () => context.push('/items/new'))
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(itemsProvider.future),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => ListTile(
                      minTileHeight: 48,
                      title: Text(list[i].name),
                      onTap: () => context.push('/items/${list[i].id}'),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
```
Test skeleton: `testWidgets('AC-ITM-5 empty state', (t) async { … expect(find.text('Create item'), findsOneWidget); });`

## Native (Swift/Kotlin)
Follow the same structure: a view model exposing `Loading | Empty | Error | Content` state, a generated API client, a navigation route with typed arguments, and accessibility labels and dynamic type on every element.
