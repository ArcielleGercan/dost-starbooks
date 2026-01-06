<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function getQuestions($category, $difficulty)
    {
        try {
            $normalizedCategory = ucfirst(strtolower($category));
            $normalizedDifficulty = ucfirst(strtolower($difficulty));

            \Log::info("Fetching questions", [
                'category' => $normalizedCategory,
                'difficulty' => $normalizedDifficulty
            ]);

            // Get questions from MongoDB
            $rawQuestions = \DB::connection('mongodb')
                ->table('quiz_questions')
                ->where('category', $normalizedCategory)
                ->where('difficulty_level', $normalizedDifficulty)
                ->get();

            $questionCount = $rawQuestions->count();
            \Log::info("Questions found", ['count' => $questionCount]);

            if ($rawQuestions->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => "No questions found for {$normalizedCategory} - {$normalizedDifficulty}",
                    'questions' => []
                ], 404);
            }

            // Format questions
            $formattedQuestions = $rawQuestions->map(function ($question) {
                // Convert stdClass to array
                $q = json_decode(json_encode($question), true);

                // Handle MongoDB ObjectId format
                $id = '';
                if (isset($q['id']['$oid'])) {
                    $id = $q['id']['$oid'];
                } elseif (isset($q['_id']['$oid'])) {
                    $id = $q['_id']['$oid'];
                } elseif (isset($q['id'])) {
                    $id = (string) $q['id'];
                } elseif (isset($q['_id'])) {
                    $id = (string) $q['_id'];
                } else {
                    $id = uniqid();
                }

                return [
                    'id' => $id,
                    'question' => $q['question'] ?? '',
                    'choice_a' => $q['choice_a'] ?? '',
                    'choice_b' => $q['choice_b'] ?? '',
                    'choice_c' => $q['choice_c'] ?? '',
                    'choice_d' => $q['choice_d'] ?? '',
                    'correct_answer' => $q['correct_answer'] ?? '',
                    'category' => $q['category'] ?? '',
                    'difficulty_level' => $q['difficulty_level'] ?? '',
                ];
            })
            ->shuffle()
            ->take(10) // Take up to 10 (or fewer if not enough available)
            ->values();

            $finalCount = $formattedQuestions->count();

            // Warn if fewer than 10 questions
            $warning = null;
            if ($finalCount < 10) {
                $warning = "Only {$finalCount} questions available for this category and difficulty.";
                \Log::warning($warning);
            }

            return response()->json([
                'success' => true,
                'count' => $finalCount,
                'warning' => $warning,
                'questions' => $formattedQuestions
            ]);

        } catch (\Exception $e) {
            \Log::error("Error in getQuestions", [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error fetching questions',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function debug()
    {
        try {
            $total = \DB::connection('mongodb')->table('quiz_questions')->count();

            // Manual distinct by grouping
            $categoriesRaw = \DB::connection('mongodb')
                ->table('quiz_questions')
                ->select('category')
                ->groupBy('category')
                ->get();

            $categories = $categoriesRaw->pluck('category')->filter()->unique()->values()->toArray();

            $difficultiesRaw = \DB::connection('mongodb')
                ->table('quiz_questions')
                ->select('difficulty_level')
                ->groupBy('difficulty_level')
                ->get();

            $difficulties = $difficultiesRaw->pluck('difficulty_level')->filter()->unique()->values()->toArray();

            // Detailed breakdown
            $breakdown = [];
            foreach (['Math', 'Science'] as $cat) {
                foreach (['Easy', 'Average', 'Difficult'] as $diff) {
                    $count = \DB::connection('mongodb')
                        ->table('quiz_questions')
                        ->where('category', $cat)
                        ->where('difficulty_level', $diff)
                        ->count();
                    $breakdown["{$cat} - {$diff}"] = $count;
                }
            }

            // Get sample from each category
            $samples = [];
            foreach (['Math', 'Science'] as $cat) {
                $sample = \DB::connection('mongodb')
                    ->table('quiz_questions')
                    ->where('category', $cat)
                    ->limit(2)
                    ->get()
                    ->map(function($q) {
                        return json_decode(json_encode($q), true);
                    });
                $samples[$cat] = $sample;
            }

            return response()->json([
                'success' => true,
                'total_questions' => $total,
                'categories_found' => $categories,
                'difficulties_found' => $difficulties,
                'breakdown' => $breakdown,
                'sample_questions' => $samples,
                'warnings' => [
                    'Science Difficult only has 4 questions - need at least 10 for proper quiz'
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    public function getStatistics()
    {
        try {
            $stats = [
                'total' => \DB::connection('mongodb')->table('quiz_questions')->count(),
                'by_category' => [
                    'Math' => \DB::connection('mongodb')->table('quiz_questions')->where('category', 'Math')->count(),
                    'Science' => \DB::connection('mongodb')->table('quiz_questions')->where('category', 'Science')->count(),
                ],
                'by_difficulty' => [
                    'Easy' => \DB::connection('mongodb')->table('quiz_questions')->where('difficulty_level', 'Easy')->count(),
                    'Average' => \DB::connection('mongodb')->table('quiz_questions')->where('difficulty_level', 'Average')->count(),
                    'Difficult' => \DB::connection('mongodb')->table('quiz_questions')->where('difficulty_level', 'Difficult')->count(),
                ],
            ];

            return response()->json([
                'success' => true,
                'statistics' => $stats
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching statistics',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
