/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:ffi';

import '../dlib.dart';

import '../types.dart';

// CoreMl Delegate bindings

// Return a delegate that uses CoreML for ops execution.
// Must outlive the interpreter.
Pointer<TfLiteDelegate> Function(Pointer<TfLiteCoreMlDelegateOptions> options)
    tfliteCoreMlDelegateCreate = tflitelib
        .lookup<NativeFunction<_TfLiteCoreMlDelegateCreateNativeT>>(
            'TfLiteCoreMlDelegateCreate')
        .asFunction();

typedef _TfLiteCoreMlDelegateCreateNativeT = Pointer<TfLiteDelegate> Function(
    Pointer<TfLiteCoreMlDelegateOptions> options);

// Do any needed cleanup and delete 'delegate'.
void Function(Pointer<TfLiteDelegate>) tfliteCoreMlDelegateDelete = tflitelib
    .lookup<NativeFunction<_TfLiteCoreMlDelegateDeleteNativeT>>(
        'TfLiteCoreMlDelegateDelete')
    .asFunction();

typedef _TfLiteCoreMlDelegateDeleteNativeT = Void Function(
    Pointer<TfLiteDelegate> delegate);
