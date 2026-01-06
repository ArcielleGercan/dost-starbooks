<?php

namespace App\Http\Controllers;

use App\Models\PlayerBadge;
use App\Models\PlayerReward;
use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;

class BadgeController extends Controller
{
    /**
     * Get player badge summary
     * Returns progress, earned badges, and unclaimed badges
     */
    public function getPlayerSummary($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Get player's badge tracking record
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'progress' => [
                            'easy' => ['current_count' => 0, 'remaining' => 3, 'total_earned' => 0],
                            'average' => ['current_count' => 0, 'remaining' => 3, 'total_earned' => 0],
                            'difficult' => ['current_count' => 0, 'remaining' => 3, 'total_earned' => 0],
                        ],
                        'official_badges' => [
                            'easy' => 0,
                            'average' => 0,
                            'difficult' => 0,
                        ],
                        'unclaimed' => [
                            'easy' => 0,
                            'average' => 0,
                            'difficult' => 0,
                        ]
                    ]
                ]);
            }

            // Calculate progress for each difficulty
            $easyProgress = $this->calculateProgress($playerBadge->easy_badge_count ?? 0);
            $averageProgress = $this->calculateProgress($playerBadge->average_badge_count ?? 0);
            $difficultProgress = $this->calculateProgress($playerBadge->difficult_badge_count ?? 0);

            // Get unclaimed badge counts from player_rewards collection
            $unclaimedCounts = PlayerReward::getUnclaimedCountByDifficulty($playerId);

            $data = [
                'progress' => [
                    'easy' => $easyProgress,
                    'average' => $averageProgress,
                    'difficult' => $difficultProgress,
                ],
                'official_badges' => [
                    'easy' => $playerBadge->easy_official_badge ?? 0,
                    'average' => $playerBadge->average_official_badge ?? 0,
                    'difficult' => $playerBadge->difficult_official_badge ?? 0,
                ],
                'unclaimed' => $unclaimedCounts,
                'total_official_badges' => ($playerBadge->easy_official_badge ?? 0) +
                                          ($playerBadge->average_official_badge ?? 0) +
                                          ($playerBadge->difficult_official_badge ?? 0),
                'total_unclaimed' => array_sum($unclaimedCounts),
            ];

            return response()->json([
                'success' => true,
                'data' => $data
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching badge summary: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching badge summary'
            ], 500);
        }
    }

    /**
     * Calculate progress to next badge (0-2 in current set)
     */
    private function calculateProgress($totalCount)
    {
        $currentInSet = $totalCount % 3;
        return [
            'current_count' => $currentInSet,
            'remaining' => 3 - $currentInSet,
            'total_earned' => $totalCount
        ];
    }

    public function claimBadge(Request $request, $playerId)
    {
        try {
            $validated = $request->validate([
                'reward_id' => 'required|string'
            ]);

            \Log::info("Claim badge request", [
                'player_id' => $playerId,
                'reward_id' => $validated['reward_id']
            ]);

            try {
                $rewardId = new ObjectId($validated['reward_id']);
            } catch (\Exception $e) {
                \Log::error("Invalid ObjectId format: " . $validated['reward_id']);
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid badge ID format'
                ], 400);
            }

            $playerObjectId = new ObjectId($playerId);

            // VALIDATION 1: Find the reward
            $reward = PlayerReward::where('_id', $rewardId)
                ->where('player_id', $playerObjectId)
                ->first();

            if (!$reward) {
                \Log::warning("Reward not found for player {$playerId}, reward_id: {$validated['reward_id']}");
                return response()->json([
                    'success' => false,
                    'message' => 'Reward not found'
                ], 404);
            }

            // VALIDATION 2: Check if already claimed
            if ($reward->claimed) {
                \Log::warning("Reward already claimed for player {$playerId}, reward_id: {$validated['reward_id']}");
                return response()->json([
                    'success' => false,
                    'message' => 'Badge already claimed'
                ], 400);
            }

            // ✅ VALIDATION 3: Get or create player badge record
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                \Log::warning("Player badge record not found for player {$playerId}, creating one now");

                // ✅ CREATE THE RECORD if it doesn't exist
                $playerBadge = PlayerBadge::create([
                    'player_info_id' => $playerObjectId,
                    'easy_badge_count' => 0,
                    'average_badge_count' => 0,
                    'difficult_badge_count' => 0,
                    'easy_official_badge' => 0,
                    'average_official_badge' => 0,
                    'difficult_official_badge' => 0,
                ]);

                \Log::info("Created new player badge record for player {$playerId}");
            }

            // VALIDATION 4: Verify eligibility (player must have 3 badges in this difficulty)
            $difficulty = $reward->difficulty;
            $badgeCountField = strtolower($difficulty) . '_badge_count';
            $currentBadgeCount = $playerBadge->$badgeCountField ?? 0;
            $currentInSet = $currentBadgeCount % 3;

            if ($currentInSet != 0) {
                \Log::warning("Player {$playerId} not eligible to claim {$difficulty} badge. Current count in set: {$currentInSet}");
                return response()->json([
                    'success' => false,
                    'message' => 'Not eligible to claim badge. You need 3 badges to claim a reward.'
                ], 400);
            }

            // All validations passed - claim the reward
            $reward->claimed = true;
            $reward->claimed_date = now();
            $reward->save();

            // Update official badge count
            $officialBadgeField = strtolower($difficulty) . '_official_badge';
            $playerBadge->$officialBadgeField = ($playerBadge->$officialBadgeField ?? 0) + 1;
            $playerBadge->save();

            \Log::info("Badge claimed successfully for player {$playerId}, difficulty: {$difficulty}, badge_number: {$reward->badge_number}");

            return response()->json([
                'success' => true,
                'message' => 'Badge claimed successfully!',
                'data' => [
                    'difficulty' => $reward->difficulty,
                    'badge_number' => $reward->badge_number,
                    'claimed_at' => $reward->claimed_date,
                    'total_official_badges' => $playerBadge->$officialBadgeField,
                ]
            ]);

        } catch (\MongoDB\Driver\Exception\InvalidArgumentException $e) {
            \Log::error("Invalid ObjectId format: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Invalid badge ID format'
            ], 400);
        } catch (\Exception $e) {
            \Log::error('Error claiming badge: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badge: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all rewards (claimed and unclaimed) for a player
     */
    public function getPlayerRewards($playerId)
    {
        try {
            $playerObjectId = new ObjectId($playerId);

            // Check if player has badge record
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'easy' => [],
                        'average' => [],
                        'difficult' => []
                    ],
                    'summary' => [
                        'easy_total' => 0,
                        'average_total' => 0,
                        'difficult_total' => 0,
                    ]
                ]);
            }

            // Get all rewards for this player, grouped by difficulty
            $allRewards = PlayerReward::byPlayer($playerId)
                ->orderBy('earned_date', 'desc')
                ->get();

            $groupedRewards = [
                'easy' => $allRewards->where('difficulty', 'easy')->values(),
                'average' => $allRewards->where('difficulty', 'average')->values(),
                'difficult' => $allRewards->where('difficulty', 'difficult')->values(),
            ];

            return response()->json([
                'success' => true,
                'data' => $groupedRewards,
                'summary' => [
                    'easy_total' => $playerBadge->easy_official_badge ?? 0,
                    'average_total' => $playerBadge->average_official_badge ?? 0,
                    'difficult_total' => $playerBadge->difficult_official_badge ?? 0,
                ],
                'unclaimed' => PlayerReward::getUnclaimedCountByDifficulty($playerId),
                'claimed' => PlayerReward::getClaimedCountByDifficulty($playerId),
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching player rewards: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching player rewards'
            ], 500);
        }
    }

    /**
     * Get unclaimed rewards for a player (for badge claim screen)
     */
    public function getUnclaimedRewards($playerId)
    {
        try {
            $unclaimedRewards = PlayerReward::getUnclaimedForPlayer($playerId);

            // Convert ObjectIds to strings for each difficulty group
            $groupedRewards = [
                'easy' => $unclaimedRewards->where('difficulty', 'easy')->map(function($reward) {
                    return [
                        '_id' => (string) $reward->_id,  // ✅ Ensure this is a string
                        'player_id' => (string) $reward->player_id,
                        'difficulty' => $reward->difficulty,
                        'badge_number' => $reward->badge_number,
                        'earned_date' => $reward->earned_date?->toIso8601String(),
                        'claimed' => $reward->claimed,
                    ];
                })->values()->toArray(),

                'average' => $unclaimedRewards->where('difficulty', 'average')->map(function($reward) {
                    return [
                        '_id' => (string) $reward->_id,  // ✅ Ensure this is a string
                        'player_id' => (string) $reward->player_id,
                        'difficulty' => $reward->difficulty,
                        'badge_number' => $reward->badge_number,
                        'earned_date' => $reward->earned_date?->toIso8601String(),
                        'claimed' => $reward->claimed,
                    ];
                })->values()->toArray(),

                'difficult' => $unclaimedRewards->where('difficulty', 'difficult')->map(function($reward) {
                    return [
                        '_id' => (string) $reward->_id,  // ✅ Ensure this is a string
                        'player_id' => (string) $reward->player_id,
                        'difficulty' => $reward->difficulty,
                        'badge_number' => $reward->badge_number,
                        'earned_date' => $reward->earned_date?->toIso8601String(),
                        'claimed' => $reward->claimed,
                    ];
                })->values()->toArray(),
            ];

            $counts = PlayerReward::getUnclaimedCountByDifficulty($playerId);

            return response()->json([
                'success' => true,
                'data' => $groupedRewards,
                'counts' => $counts,
                'total_unclaimed' => array_sum($counts),
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching unclaimed rewards: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error fetching unclaimed rewards'
            ], 500);
        }
    }

    /**
     * Claim all unclaimed badges for a specific difficulty
     */
    public function claimAllByDifficulty(Request $request, $playerId)
    {
        try {
            $validated = $request->validate([
                'difficulty' => 'required|in:easy,average,difficult'
            ]);

            $difficulty = $validated['difficulty'];
            $playerObjectId = new ObjectId($playerId);

            // Get player badge record for validation
            $playerBadge = PlayerBadge::where('player_info_id', $playerObjectId)->first();

            if (!$playerBadge) {
                return response()->json([
                    'success' => false,
                    'message' => 'Player badge record not found'
                ], 404);
            }

            // Get all unclaimed rewards for this difficulty
            $unclaimedRewards = PlayerReward::byPlayer($playerId)
                ->byDifficulty($difficulty)
                ->unclaimed()
                ->get();

            if ($unclaimedRewards->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No unclaimed badges for this difficulty'
                ], 404);
            }

            $claimedCount = 0;
            $officialBadgeField = strtolower($difficulty) . '_official_badge';

            foreach ($unclaimedRewards as $reward) {
                if ($reward->claim()) {
                    $claimedCount++;

                    // Update official badge count
                    $playerBadge->$officialBadgeField = ($playerBadge->$officialBadgeField ?? 0) + 1;
                }
            }

            $playerBadge->save();

            return response()->json([
                'success' => true,
                'message' => "Successfully claimed {$claimedCount} {$difficulty} badge(s)!",
                'data' => [
                    'difficulty' => $difficulty,
                    'claimed_count' => $claimedCount,
                    'total_official_badges' => $playerBadge->$officialBadgeField,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Error claiming all badges: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error claiming badges'
            ], 500);
        }
    }
}
