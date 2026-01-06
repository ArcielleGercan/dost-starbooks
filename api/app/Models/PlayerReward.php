<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PlayerReward extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'player_rewards';

    protected $fillable = [
        'player_id',
        'difficulty',
        'badge_number',
        'earned_date',
        'claimed',
        'claimed_date',
    ];

    protected $casts = [
        '_id' => 'string',
        'badge_number' => 'integer',
        'claimed' => 'boolean',
        'earned_date' => 'datetime',
        'claimed_date' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the player who owns this reward
     */
    public function player()
    {
        return $this->belongsTo(User::class, 'player_id', '_id');
    }

    /**
     * Scope: Get unclaimed rewards
     */
    public function scopeUnclaimed($query)
    {
        return $query->where('claimed', false);
    }

    /**
     * Scope: Get claimed rewards
     */
    public function scopeClaimed($query)
    {
        return $query->where('claimed', true);
    }

    /**
     * Scope: Filter by difficulty
     */
    public function scopeByDifficulty($query, $difficulty)
    {
        return $query->where('difficulty', strtolower($difficulty));
    }

    /**
     * Scope: Filter by player
     */
    public function scopeByPlayer($query, $playerId)
    {
        return $query->where('player_id', new \MongoDB\BSON\ObjectId($playerId));
    }

    /**
     * Claim this reward
     */
    public function claim()
    {
        if ($this->claimed) {
            return false; // Already claimed
        }

        $this->update([
            'claimed' => true,
            'claimed_date' => now()
        ]);

        return true;
    }

    /**
     * Check if reward is claimable
     */
    public function isClaimable(): bool
    {
        return !$this->claimed;
    }

    /**
     * Get all unclaimed rewards for a player
     */
    public static function getUnclaimedForPlayer($playerId, $difficulty = null)
    {
        $query = self::byPlayer($playerId)->unclaimed();

        if ($difficulty) {
            $query = $query->byDifficulty($difficulty);
        }

        return $query->orderBy('earned_date', 'desc')->get();
    }

    /**
     * Get count of unclaimed rewards by difficulty for a player
     */
    public static function getUnclaimedCountByDifficulty($playerId)
    {
        $playerObjectId = new \MongoDB\BSON\ObjectId($playerId);

        return [
            'easy' => self::byPlayer($playerId)
                ->byDifficulty('easy')
                ->unclaimed()
                ->count(),
            'average' => self::byPlayer($playerId)
                ->byDifficulty('average')
                ->unclaimed()
                ->count(),
            'difficult' => self::byPlayer($playerId)
                ->byDifficulty('difficult')
                ->unclaimed()
                ->count(),
        ];
    }

    /**
     * Get total claimed badges by difficulty for a player
     */
    public static function getClaimedCountByDifficulty($playerId)
    {
        return [
            'easy' => self::byPlayer($playerId)
                ->byDifficulty('easy')
                ->claimed()
                ->count(),
            'average' => self::byPlayer($playerId)
                ->byDifficulty('average')
                ->claimed()
                ->count(),
            'difficult' => self::byPlayer($playerId)
                ->byDifficulty('difficult')
                ->claimed()
                ->count(),
        ];
    }
}
