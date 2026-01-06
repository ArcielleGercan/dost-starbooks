<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class FastestTime extends Model
{
    protected $connection = 'mongodb';
    // Collection is dynamically set based on game_type
    // 'fastest_time_memory_match' or 'fastest_time_puzzle'

    protected $fillable = [
        'player_id',
        'player_username',
        'game_type', // 'memory_match' or 'puzzle'
        'difficulty', // 'EASY', 'AVERAGE', 'DIFFICULT'
        'category', // For puzzle only
        'time_seconds',
        'moves',
        'achieved_at',
    ];

    protected $casts = [
        'time_seconds' => 'integer',
        'moves' => 'integer',
        'achieved_at' => 'datetime',
    ];

    /**
     * Override collection based on game_type
     */
    public function getTable()
    {
        if (isset($this->attributes['game_type'])) {
            $gameType = $this->attributes['game_type'];
            return $gameType === 'memory_match'
                ? 'fastest_time_memory_match'
                : 'fastest_time_puzzle';
        }
        return 'fastest_time_memory_match'; // default
    }

    /**
     * Get player info
     */
    public function player()
    {
        return $this->belongsTo(User::class, 'player_id', '_id');
    }

    /**
     * Scope: Get records by game type
     */
    public function scopeByGameType($query, $gameType)
    {
        return $query->where('game_type', $gameType);
    }

    /**
     * Scope: Get records by difficulty
     */
    public function scopeByDifficulty($query, $difficulty)
    {
        return $query->where('difficulty', $difficulty);
    }

    /**
     * Scope: Get records by category (for puzzle)
     */
    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    /**
     * Scope: Get top N fastest times
     */
    public function scopeTopFastest($query, $limit = 10)
    {
        return $query->orderBy('time_seconds', 'asc')->limit($limit);
    }
}
