import 'package:pi_mobile/components/confirmation_dialog.dart';
import 'package:pi_mobile/models/card.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:pi_mobile/shared/theme.dart';
import 'package:pi_mobile/shared/uuid.dart';
import 'package:pi_mobile/components/card.dart';
import 'package:pi_mobile/components/bottom_bar.dart';
import 'package:pi_mobile/components/selection_app_bar.dart';
import 'package:pi_mobile/draggable_masonry_layout.dart';
import 'package:pi_mobile/providers/card_providers.dart';
import 'package:pi_mobile/providers/connection_settings_provider.dart';
import 'package:pi_mobile/providers/extensions_provider.dart';
import 'package:pi_mobile/screens/archived_cards.dart';
import 'package:pi_mobile/screens/card_renderer.dart';
import 'package:pi_mobile/screens/connections_screen.dart';
import 'package:pi_mobile/screens/extensions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CardsProvider()..initializeCards(_buildInitialCards()),
        ),
        ChangeNotifierProvider(create: (_) => ExtensionsProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionSettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

List<CardData> _buildInitialCards() {
  const loremIpsum =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. ';
  final repeatedLorem = loremIpsum * 3;
  final lengths = [50, 120, 250, 400, 600, 800];
  final statuses = [
    CardStatus.normal,
    CardStatus.hasUpdate,
    CardStatus.normal,
    CardStatus.stale,
    CardStatus.normal,
    CardStatus.normal,
  ];
  final generatedIds = <String>{};
  return List<CardData>.generate(lengths.length, (index) {
    final length = lengths[index];
    final text = repeatedLorem.substring(
      0,
      length > repeatedLorem.length ? repeatedLorem.length : length,
    );
    final id = generateUniqueUuid(
      (candidate) => generatedIds.contains(candidate),
    );
    generatedIds.add(id);
    return CardData(
      id: id,
      title: 'Card ${index + 1}',
      content: text,
      isArchived: index == 1,
      status: statuses[index],
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comment',
      debugShowCheckedModeBanner: false,
      theme: darkNeutralTheme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSettingsPopupOpen = false;
  bool _isNewCardPopupOpen = false;

  void _setSettingsPopupOpen(bool isOpen) {
    if (_isSettingsPopupOpen == isOpen) {
      return;
    }
    setState(() {
      _isSettingsPopupOpen = isOpen;
    });
  }

  void _closeSettingsPopup() {
    _setSettingsPopupOpen(false);
  }

  void _toggleSettingsPopup() {
    _setSettingsPopupOpen(!_isSettingsPopupOpen);
  }

  void _setNewCardPopupOpen(bool isOpen) {
    if (_isNewCardPopupOpen == isOpen) {
      return;
    }
    setState(() {
      _isNewCardPopupOpen = isOpen;
    });
  }

  void _closeNewCardPopup() {
    _setNewCardPopupOpen(false);
  }

  void _toggleNewCardPopup() {
    _setNewCardPopupOpen(!_isNewCardPopupOpen);
  }

  void _createNewCard() {
    _closeNewCardPopup();
    final provider = context.read<CardsProvider>();
    final nextIndex = provider.allCards.length + 1;
    final id = generateUniqueUuid(
      (candidate) => provider.allCards.any((card) => card.id == candidate),
    );
    provider.addCard(
      CardData(
        id: id,
        title: 'Card $nextIndex',
        content:
            'New card content for item $nextIndex. Add your own text here to test fuzzy search quickly.',
        status: CardStatus.stale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsProvider = context.watch<CardsProvider>();
    final isSelectionMode = cardsProvider.isSelectionMode;

    if (isSelectionMode && (_isSettingsPopupOpen || _isNewCardPopupOpen)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _closeSettingsPopup();
          _closeNewCardPopup();
        }
      });
    }

    void closeSearchIfOpen() {
      final provider = context.read<CardsProvider>();
      if (provider.isSearchOpen) {
        provider.closeSearch();
      }
    }

    final cards = cardsProvider.cards
        .map((cardData) {
          return DraggableMasonryItem(
            id: cardData.id,
            child: Card(
              title: cardData.title,
              color: cardData.color,
              status: cardData.status,
              isSelected: cardsProvider.isSelected(cardData.id),
              onTap: () {
                if (isSelectionMode) {
                  cardsProvider.toggleSelection(cardData.id);
                  return;
                }
                switch (cardData.status) {
                  case CardStatus.normal:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardRendererScreen(cardId: cardData.id),
                      ),
                    );
                    break;
                  case CardStatus.hasUpdate:
                    cardsProvider.setCardStatus(cardData.id, CardStatus.normal);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardRendererScreen(cardId: cardData.id),
                      ),
                    );
                    break;
                  case CardStatus.stale:
                    showGlassConfirmationDialog(
                      context,
                      title: "This card is stale meaning it won't update any sessions and is read-only",
                      confirmLabel: "View",
                      confirmTextColor: Colors.red,
                      onConfirm: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CardRendererScreen(cardId: cardData.id),
                          ),
                        );
                      }
                    );
                    break;
                } 
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Text(cardData.content),
              ),
            ),
          );
        })
        .toList(growable: false);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: isSelectionMode ? const SelectionAppBar() : null,
      bottomNavigationBar: isSelectionMode
          ? null
          : BottomBar(
              isSettingsPopupOpen: _isSettingsPopupOpen,
              isSearchOpen: cardsProvider.isSearchOpen,
              searchQuery: cardsProvider.searchQuery,
              isNewCardPopupOpen: _isNewCardPopupOpen,
              onSettingsPopupOpen: () {
                closeSearchIfOpen();
                _closeNewCardPopup();
                _toggleSettingsPopup();
              },
              onNewCardPopupOpen: () {
                closeSearchIfOpen();
                _closeSettingsPopup();
                _toggleNewCardPopup();
              },
              onNewCardPopupClose: _closeNewCardPopup,
              onNewCard: _createNewCard,
              onSearchOpen: () {
                _closeSettingsPopup();
                _closeNewCardPopup();
                context.read<CardsProvider>().openSearch();
              },
              onSearchChanged: (query) =>
                  context.read<CardsProvider>().filterCards(query),
              onSearchClose: () => context.read<CardsProvider>().closeSearch(),
              onSearchSubmit: () =>
                  context.read<CardsProvider>().closeSearchKeepingFilters(),
              onExtensions: () {
                closeSearchIfOpen();
                _closeSettingsPopup();
                _closeNewCardPopup();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExtensionsScreen()),
                );
              },
              onConnections: () {
                closeSearchIfOpen();
                _closeSettingsPopup();
                _closeNewCardPopup();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                );
              },
              onArchive: () {
                closeSearchIfOpen();
                _closeSettingsPopup();
                _closeNewCardPopup();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ArchivedCardsScreen(),
                  ),
                );
              },
            ),
      body: Stack(
        children: [
          DraggableMasonryLayout(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
            enableDrag: !isSelectionMode,
            onReorder: (draggedId, targetId) {
              context.read<CardsProvider>().reorderCardsById(
                draggedId: draggedId,
                targetId: targetId,
                archivedOnly: false,
              );
            },
            onSamePlaceDrop: (cardId) {
              final provider = context.read<CardsProvider>();
              provider.enterSelectionMode(cardId);
            },
            items: cards,
          ),
          if (!isSelectionMode &&
              (cardsProvider.isSearchOpen ||
                  _isSettingsPopupOpen ||
                  _isNewCardPopupOpen))
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (cardsProvider.isSearchOpen) {
                    context.read<CardsProvider>().closeSearch();
                  }
                  if (_isSettingsPopupOpen) {
                    _closeSettingsPopup();
                  }
                  if (_isNewCardPopupOpen) {
                    _closeNewCardPopup();
                  }
                },
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.16)),
              ),
            ),
        ],
      ),
    );
  }
}
