<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use MongoDB\BSON\ObjectId;

class StarsController extends Controller
{
    /**
     * Award stars to a player for game completion
     * This endpoint handles star calculations and milestone tracking
     */
    public function awardStars(Request $request, $playerId)
    {
        $validator = Validator::make($request->all(), [
            'stars' => 'required|integer|min:1',
            'game_type' => 'required|string|in:memory_match,puzzle,challenge,battle',
            'difficulty' => 'required|string|in:EASY,AVERAGE,DIFFICULT',
            'category' => 'nullable|string', // For puzzle games
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $data = $validator->validated();
            $playerObjectId = new ObjectId($playerId);

            // Find the player
            $player = User::find($playerObjectId);

            if (!$player) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player not found'
                ], 404);
            }

            // Get current stars
            $currentStars = $player->stars ?? 0;
            $previousTier = $this->getStarTier($currentStars);

            // Add new stars
            $newTotal = $currentStars + $data['stars'];
            $player->stars = $newTotal;
            $player->save();

            // Check for new milestone
            $newTier = $this->getStarTier($newTotal);
            $newMilestone = null;

            if ($newTier['tier'] !== $previousTier['tier']) {
                $newMilestone = [
                    'tier' => $newTier['tier'],
                    'icon' => $newTier['icon'],
                    'prize' => $newTier['prize'],
                    'stars_required' => $newTier['threshold'],
                ];

                // Log milestone achievement
                $this->logMilestone($playerId, $newMilestone, $newTotal);
            }

            return response()->json([
                'success' => true,
                'message' => 'Stars awarded successfully',
                'stars_earned' => $data['stars'],
                'total_stars' => $newTotal,
                'previous_stars' => $currentStars,
                'new_milestone' => $newMilestone,
                'current_tier' => $newTier,
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Error awarding stars: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error awarding stars',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's current star count and tier
     */
    public function getPlayerStars($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);
            $player = User::find($playerObjectId);

            if (!$player) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player not found'
                ], 404);
            }

            $stars = $player->stars ?? 0;
            $tier = $this->getStarTier($stars);
            $nextTier = $this->getNextTier($stars);

            return response()->json([
                'success' => true,
                'data' => [
                    'total_stars' => $stars,
                    'current_tier' => $tier,
                    'next_tier' => $nextTier,
                    'progress_to_next' => $nextTier ? [
                        'current' => $stars,
                        'required' => $nextTier['threshold'],
                        'remaining' => $nextTier['threshold'] - $stars,
                        'percentage' => min(100, round(($stars / $nextTier['threshold']) * 100, 2)),
                    ] : null,
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player stars',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get star tier information based on total stars
     */
    private function getStarTier($stars)
    {
        $tiers = [
            ['tier' => 'Diamond', 'threshold' => 1000, 'icon' => '💎', 'prize' => 'Diamond Badge Unlocked!', 'color' => '#B9F2FF'],
            ['tier' => 'Platinum', 'threshold' => 500, 'icon' => '🏆', 'prize' => 'Platinum Badge Unlocked!', 'color' => '#E5E4E2'],
            ['tier' => 'Gold', 'threshold' => 250, 'icon' => '🥇', 'prize' => 'Gold Badge Unlocked!', 'color' => '#FFD700'],
            ['tier' => 'Silver', 'threshold' => 100, 'icon' => '🥈', 'prize' => 'Silver Badge Unlocked!', 'color' => '#C0C0C0'],
            ['tier' => 'Bronze', 'threshold' => 50, 'icon' => '🥉', 'prize' => 'Bronze Badge Unlocked!', 'color' => '#CD7F32'],
            ['tier' => 'Beginner', 'threshold' => 0, 'icon' => '⭐', 'prize' => 'Welcome to Starbooks Whiz!', 'color' => '#FFFFFF'],
        ];

        foreach ($tiers as $tier) {
            if ($stars >= $tier['threshold']) {
                return $tier;
            }
        }

        return $tiers[count($tiers) - 1]; // Return beginner tier as fallback
    }

    /**
     * Get next tier information
     */
    private function getNextTier($stars)
    {
        $tiers = [
            ['tier' => 'Diamond', 'threshold' => 1000, 'icon' => '💎', 'prize' => 'Diamond Badge Unlocked!'],
            ['tier' => 'Platinum', 'threshold' => 500, 'icon' => '🏆', 'prize' => 'Platinum Badge Unlocked!'],
            ['tier' => 'Gold', 'threshold' => 250, 'icon' => '🥇', 'prize' => 'Gold Badge Unlocked!'],
            ['tier' => 'Silver', 'threshold' => 100, 'icon' => '🥈', 'prize' => 'Silver Badge Unlocked!'],
            ['tier' => 'Bronze', 'threshold' => 50, 'icon' => '🥉', 'prize' => 'Bronze Badge Unlocked!'],
        ];

        foreach ($tiers as $tier) {
            if ($stars < $tier['threshold']) {
                return $tier;
            }
        }

        return null; // Already at max tier
    }

    /**
     * Log milestone achievement to database
     */
    private function logMilestone($playerId, $milestone, $totalStars)
    {
        try {
            \DB::connection('mongodb')->table('star_milestones')->insert([
                'player_id' => new ObjectId($playerId),
                'tier' => $milestone['tier'],
                'icon' => $milestone['icon'],
                'prize' => $milestone['prize'],
                'stars_at_achievement' => $totalStars,
                'achieved_at' => now(),
            ]);
        } catch (\Exception $e) {
            \Log::error('Error logging milestone: ' . $e->getMessage());
        }
    }

    /**
     * Get player's milestone history
     */
    public function getMilestoneHistory($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            $milestones = \DB::connection('mongodb')
                ->table('star_milestones')
                ->where('player_id', $playerObjectId)
                ->orderBy('achieved_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $milestones,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching milestone history',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get leaderboard ranked by total stars
     */
    public function getStarsLeaderboard(Request $request)
    {
        try {
            $limit = $request->query('limit', 100);

            $leaderboard = \DB::connection('mongodb')
                ->table('player_info')
                ->orderBy('stars', 'desc')
                ->limit($limit)
                ->get()
                ->map(function($player, $index) {
                    $stars = $player->stars ?? 0;
                    $tier = $this->getStarTier($stars);

                    return [
                        'rank' => $index + 1,
                        'player_id' => (string)$player->_id,
                        'username' => $player->username ?? 'Unknown',
                        'avatar' => $player->avatar ?? 'assets/images-avatars/Adventurer.png',
                        'stars' => $stars,
                        'tier' => $tier['tier'],
                        'tier_icon' => $tier['icon'],
                        'tier_color' => $tier['color'],
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $leaderboard,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching stars leaderboard',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get player's rank in stars leaderboard
     */
    public function getPlayerStarsRank($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);
            $player = User::find($playerObjectId);

            if (!$player) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player not found'
                ], 404);
            }

            $playerStars = $player->stars ?? 0;

            // Count how many players have more stars
            $rank = \DB::connection('mongodb')
                ->table('player_info')
                ->where('stars', '>', $playerStars)
                ->count() + 1;

            $totalPlayers = \DB::connection('mongodb')
                ->table('player_info')
                ->count();

            $tier = $this->getStarTier($playerStars);

            return response()->json([
                'success' => true,
                'data' => [
                    'rank' => $rank,
                    'total_players' => $totalPlayers,
                    'stars' => $playerStars,
                    'tier' => $tier,
                    'percentile' => round((($totalPlayers - $rank) / $totalPlayers) * 100, 2),
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player rank',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
