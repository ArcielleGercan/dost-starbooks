<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\User;
use MongoDB\BSON\ObjectId;

class UserController extends Controller
{
    public function register(Request $request)
    {
        try {
            $validated = $request->validate([
                'username' => [
                    'required',
                    'unique:player_info,username',
                    'min:3',
                    'max:20',
                    'regex:/^[a-zA-Z0-9_]+$/',  // This already prevents spaces, but let's add custom validation
                    function ($attribute, $value, $fail) {
                        if (preg_match('/\s/', $value)) {
                            $fail('Username cannot contain spaces');
                        }
                    },
                ],
                'password' => [
                    'required',
                    'min:8',
                    'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]+$/'
                ],
                'school' => 'required|min:2',
                'age' => 'required|string',
                'avatar' => 'required|string',
                'category' => 'required|string',
                'sex' => 'required|in:Male,Female',
                'region' => 'required|integer',
                'province' => 'required|integer',
                'city' => 'required|integer',
            ], [
                // Custom error messages matching Flutter app expectations
                'username.required' => 'Username is required',
                'username.unique' => 'Username is already taken',
                'username.min' => 'Username must be at least 3 characters',
                'username.max' => 'Username must not exceed 20 characters',
                'username.regex' => 'Username can only contain letters, numbers, and underscores',

                'password.required' => 'Password is required',
                'password.min' => 'Password must be at least 8 characters',
                'password.regex' => 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',

                'school.required' => 'School is required',
                'school.min' => 'School name must be at least 2 characters',

                'age.required' => 'Please select an age range',
                'avatar.required' => 'Avatar is required',
                'category.required' => 'Category is required',
                'sex.required' => 'Sex is required',
                'sex.in' => 'Sex must be either Male or Female',

                'region.required' => 'Region is required',
                'region.integer' => 'Invalid region selected',
                'province.required' => 'Province is required',
                'province.integer' => 'Invalid province selected',
                'city.required' => 'City is required',
                'city.integer' => 'Invalid city selected',
            ]);

        } catch (ValidationException $e) {
            // Return the first validation error message
            $errors = $e->errors();
            $firstError = reset($errors);
            $message = is_array($firstError) ? $firstError[0] : $firstError;

            return response()->json([
                'success' => false,
                'message' => $message,
                'errors' => $errors
            ], 422);
        }

        try {
            $user = User::create([
                'username' => $validated['username'],
                'password' => Hash::make($validated['password']),
                'school' => $validated['school'],
                'age' => $validated['age'],
                'avatar' => $validated['avatar'],
                'category' => $validated['category'],
                'sex' => $validated['sex'],
                'region' => (int) $validated['region'],
                'province' => (int) $validated['province'],
                'city' => (int) $validated['city'],
                'stars' => 0,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Registration successful',
                'user' => $user,
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Registration failed: ' . $e->getMessage()
            ], 500);
        }
    }

    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', $request->username)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid password',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'user' => $user,
        ]);
    }

    public function profile($id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid user ID format',
            ], 400);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }

    private function getLocationName($collection, $id, $provinceId = null)
    {
        $items = \DB::connection('mongodb')->table($collection)->get();

        if ($collection === 'city' && $provinceId !== null) {
            $item = $items->first(function ($c) use ($id, $provinceId) {
                return (string)($c->id ?? '') === (string)$id
                    && (string)($c->province_id ?? '') === (string)$provinceId;
            });
        } else {
            $item = $items->first(function ($c) use ($id) {
                return (string)($c->id ?? '') === (string)$id;
            });
        }

        return $item ? ($collection === 'region' ? $item->region_name : ($collection === 'province' ? $item->province_name : $item->city_name)) : 'Unknown';
    }

    public function homepage($id)
    {
        try {
            $user = \DB::connection('mongodb')
                ->table('player_info')
                ->where('_id', new \MongoDB\BSON\ObjectId($id))
                ->first();

            if (!$user) {
                return response()->json(['success' => false, 'message' => 'User not found'], 404);
            }

            $regionName = $this->getLocationName('region', $user->region);
            $provinceName = $this->getLocationName('province', $user->province);
            $cityName = $this->getLocationName('city', $user->city, $user->province);

            return response()->json([
                'success' => true,
                'user' => [
                    'username' => $user->username ?? '',
                    'region' => $regionName,
                    'province' => $provinceName,
                    'city' => $cityName,
                    'stars' => $user->stars ?? 0,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Error fetching homepage data',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $user = User::find(new ObjectId($id));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ID format'
            ], 400);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        try {
            $validated = $request->validate([
                'username' => [
                    'required',
                    'min:3',
                    'max:20',
                    'regex:/^[a-zA-Z0-9_]+$/',
                    function ($attribute, $value, $fail) use ($user) {
                        // Check for spaces
                        if (preg_match('/\s/', $value)) {
                            $fail('Username cannot contain spaces');
                            return;
                        }
                        // Check if username is taken by another user
                        $existing = User::where('username', $value)
                            ->where('_id', '!=', $user->_id)
                            ->first();
                        if ($existing) {
                            $fail('The username is already taken.');
                        }
                    },
                ],
                'school' => 'required|min:2',
                'age' => 'required|string',
                'avatar' => 'required|string',
                'category' => 'required|string',
                'sex' => 'required|in:Male,Female',
                'region' => 'required|integer',
                'province' => 'required|integer',
                'city' => 'required|integer',
            ], [
                'username.required' => 'Username is required',
                'username.min' => 'Username must be at least 3 characters',
                'username.max' => 'Username must not exceed 20 characters',
                'username.regex' => 'Username can only contain letters, numbers, and underscores',
                'school.required' => 'School is required',
                'school.min' => 'School name must be at least 2 characters',
                'age.required' => 'Please select an age range',
                'avatar.required' => 'Avatar is required',
                'category.required' => 'Category is required',
                'sex.required' => 'Sex is required',
                'sex.in' => 'Sex must be either Male or Female',
                'region.required' => 'Region is required',
                'region.integer' => 'Invalid region selected',
                'province.required' => 'Province is required',
                'province.integer' => 'Invalid province selected',
                'city.required' => 'City is required',
                'city.integer' => 'Invalid city selected',
            ]);

        } catch (ValidationException $e) {
            $errors = $e->errors();
            $firstError = reset($errors);
            $message = is_array($firstError) ? $firstError[0] : $firstError;

            return response()->json([
                'success' => false,
                'message' => $message,
                'errors' => $errors
            ], 422);
        }

        // Check if anything actually changed
        $hasChanges = false;

        if ($user->username !== $validated['username'] ||
            $user->school !== $validated['school'] ||
            $user->age !== $validated['age'] ||
            $user->avatar !== $validated['avatar'] ||
            $user->category !== $validated['category'] ||
            $user->sex !== $validated['sex'] ||
            (int)$user->region !== (int)$validated['region'] ||
            (int)$user->province !== (int)$validated['province'] ||
            (int)$user->city !== (int)$validated['city']) {
            $hasChanges = true;
        }

        if (!$hasChanges) {
            return response()->json([
                'success' => true,
                'message' => 'No changes were made',
                'user' => $user,
                'no_changes' => true
            ], 200);
        }

        $user->update([
            'username' => $validated['username'],
            'school' => $validated['school'],
            'age' => $validated['age'],
            'avatar' => $validated['avatar'],
            'category' => $validated['category'],
            'sex' => $validated['sex'],
            'region' => (int) $validated['region'],
            'province' => (int) $validated['province'],
            'city' => (int) $validated['city'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user
        ], 200);
    }

    public function fixUserLocationIds()
    {
        try {
            $users = \DB::connection('mongodb')->table('player_info')->get();
            $fixedUsers = [];

            foreach ($users as $user) {
                $mongoId = isset($user->_id) ? (string)$user->_id : (isset($user->id) ? (string)$user->id : null);
                if (!$mongoId) continue;

                $regionId = $user->region ?? 0;
                $provinceId = $user->province ?? 0;
                $cityId = $user->city ?? 0;

                $regionName = $this->getLocationName('region', $regionId);
                $provinceName = $this->getLocationName('province', $provinceId);
                $cityName = $this->getLocationName('city', $cityId, $provinceId);

                \DB::connection('mongodb')
                    ->table('player_info')
                    ->where('_id', new \MongoDB\BSON\ObjectId($mongoId))
                    ->update([
                        'region' => $regionId,
                        'province' => $provinceId,
                        'city' => $cityId,
                    ]);

                $fixedUsers[] = [
                    'username' => $user->username ?? 'Unknown',
                    'region' => $regionName,
                    'province' => $provinceName,
                    'city' => $cityName,
                ];
            }

            return response()->json([
                'success' => true,
                'message' => 'All user location IDs synced successfully.',
                'fixed_users' => $fixedUsers,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function changePassword(Request $request, $id)
    {
        try {
            $request->validate([
                'old_password' => 'required',
                'new_password' => [
                    'required',
                    'min:8',
                    'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]+$/'
                ],
                'new_password_confirmation' => 'required|same:new_password',
            ], [
                'old_password.required' => 'Please enter your current password.',
                'new_password.required' => 'Please enter a new password.',
                'new_password.min' => 'New password must be at least 8 characters.',
                'new_password.regex' => 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.',
                'new_password_confirmation.required' => 'Please confirm your new password.',
                'new_password_confirmation.same' => 'Password confirmation does not match.',
            ]);

        } catch (ValidationException $e) {
            $errors = $e->errors();
            $firstError = reset($errors);
            $message = is_array($firstError) ? $firstError[0] : $firstError;

            return response()->json([
                'success' => false,
                'message' => $message
            ], 422);
        }

        try {
            $user = User::find(new \MongoDB\BSON\ObjectId($id));

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            if (!Hash::check($request->old_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Old password is incorrect'
                ], 400);
            }

            if (Hash::check($request->new_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'New password must be different from the old password'
                ], 400);
            }

            $user->password = Hash::make($request->new_password);
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Password updated successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating password'
            ], 500);
        }
    }

    public function logout(Request $request)
    {
        $request->validate([
            'user_id' => 'required|string',
        ]);

        try {
            $user = User::find(new \MongoDB\BSON\ObjectId($request->user_id));

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'You have been logged out successfully.'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error during logout'
            ], 500);
        }
    }
}
