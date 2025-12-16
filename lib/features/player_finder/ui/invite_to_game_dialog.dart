import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/board_game.dart';
import '../../../core/services/game_session_service.dart';
import '../../../core/services/game_service.dart';

class InviteToGameDialog extends StatefulWidget {
  final String inviteeId;
  final String inviteeName;
  final String inviteeImage;

  const InviteToGameDialog({
    super.key,
    required this.inviteeId,
    required this.inviteeName,
    required this.inviteeImage,
  });

  @override
  State<InviteToGameDialog> createState() => _InviteToGameDialogState();
}

class _InviteToGameDialogState extends State<InviteToGameDialog> {
  final GameSessionService _sessionService = GameSessionService();
  
  // We keep the selected game object for the invite logic
  BoardGame? _selectedGame;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _locationController =
      TextEditingController(text: 'My House');

  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple,
              accentColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            dialogBackgroundColor: const Color(0xff0E141B),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple,
              accentColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            dialogBackgroundColor: const Color(0xff0E141B),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _sendInvitation() async {
    if (_selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a board game.')),
      );
      return;
    }

    final sessionDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await _sessionService.sendGameInvitation(
        inviteeId: widget.inviteeId,
        inviteeName: widget.inviteeName,
        inviteeImage: widget.inviteeImage,
        gameId: _selectedGame!.id,
        gameName: _selectedGame!.name,
        gameImageUrl: _selectedGame!.thumbnailUrl,
        date: sessionDateTime,
        time: _selectedTime.format(context),
        location: _locationController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invitation sent to ${widget.inviteeName}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send invitation: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF171A21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Invite ${widget.inviteeName}',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text('Select a Game from Your Collection:',
                style: TextStyle(color: Colors.white70)),
            
            // -----------------------------------------------------------------
            // FIX: Robust Dropdown Logic
            // -----------------------------------------------------------------
            StreamBuilder<List<BoardGame>>(
              stream: GameService.getUserCollectionGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.deepPurpleAccent));
                }
                if (snapshot.hasError) {
                  return Text('Error loading games: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                }
                
                final games = snapshot.data ?? [];
                
                if (games.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('You have no games in your collection.',
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                // 1. Remove duplicate games (by ID) to prevent crashes
                final uniqueGamesMap = <String, BoardGame>{};
                for (var game in games) {
                  uniqueGamesMap[game.id] = game;
                }
                final uniqueGames = uniqueGamesMap.values.toList();

                // 2. Validate Selection
                // We check if the currently selected ID actually exists in the new list
                final bool isSelectionValid = _selectedGame != null && 
                    uniqueGamesMap.containsKey(_selectedGame!.id);

                // If invalid or null, we don't force a reset immediately inside build 
                // (which causes the loop). We just let the dropdown render with a 
                // null value or the valid value.
                
                // We use String (ID) as the value for the Dropdown, not the object.
                final String? currentDropdownValue = isSelectionValid 
                    ? _selectedGame!.id 
                    : null;

                return DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF171A21),
                  value: currentDropdownValue,
                  hint: const Text('Choose a game',
                      style: TextStyle(color: Colors.white54)),
                  items: uniqueGames.map((game) {
                    return DropdownMenuItem<String>(
                      value: game.id, // Store ID, not Object
                      child: Text(
                        game.name,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newGameId) {
                    // When ID changes, we look up the full object
                    if (newGameId != null) {
                      setState(() {
                        _selectedGame = uniqueGamesMap[newGameId];
                      });
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.deepPurpleAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.deepPurple, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            const Text('Session Details:',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('Date', style: TextStyle(color: Colors.white)),
              subtitle: Text(_dateFormat.format(_selectedDate),
                  style: const TextStyle(color: Colors.white54)),
              trailing:
                  const Icon(Icons.calendar_today, color: Colors.white54),
              onTap: () => _selectDate(context),
            ),

            ListTile(
              title: const Text('Time', style: TextStyle(color: Colors.white)),
              subtitle: Text(_selectedTime.format(context),
                  style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.access_time, color: Colors.white54),
              onTap: () => _selectTime(context),
            ),

            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Location (e.g., My House, Online)',
                labelStyle: const TextStyle(color: Colors.white70),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _sendInvitation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
          ),
          child: const Text('Send Invite',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}