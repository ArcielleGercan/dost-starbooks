<?php

namespace App\Http\Controllers;

class CityController extends Controller
{
    public function getByProvince($provinceId)
    {
        $cities = \DB::connection('mongodb')
            ->table('city')
            ->where('province_id', (int) $provinceId)
            ->get()
            ->map(function ($city) {
                return [
                    'id' => (int) $city->id,
                    'city_name' => $city->city_name,
                    'province_id' => (int) $city->province_id,
                ];
            });

        return response()->json($cities);
    }
}
